//
//  FXRefreshFooterView.m
//  TTTT
//
//  Created by 张大宗 on 2017/3/3.
//  Copyright © 2017年 张大宗. All rights reserved.
//

#import "FXRefreshFooterView.h"
#import "FXCommon.h"
#import "UIScrollView+FXExtension.h"
#import "Masonry.h"
#import "ReactiveObjC.h"

@interface FXRefreshFooterView()

@property (nonatomic,weak) UIScrollView *refScrollView;

@property (nonatomic,weak) NSObject<UIScrollViewDelegate,IFXRefreshDelegate>* scrollViewDelegate;

@property (nonatomic,assign) FXRefreshState state;

@property (nonatomic,strong) UIView<IFXRefreshViewProtocol> *refStateView;

@property (nonatomic,assign) BOOL isLoading;

@end

@implementation FXRefreshFooterView

+ (instancetype)refreshForScrollView:(UIScrollView *)scrollView Footer:(UIView<IFXRefreshViewProtocol> *)stateView{
    FXRefreshFooterView*footerView = [[FXRefreshFooterView alloc] init];
    if (footerView) {
        [scrollView addSubview:footerView];
        [footerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(0));
            make.right.equalTo(scrollView.mas_right);
            make.top.equalTo(@(scrollView.contentSize.height));
            make.height.equalTo(scrollView.mas_height);
        }];
        [footerView initWithScrollView:scrollView Footer:stateView];

    }
    return footerView;
}

- (void)dealloc {
    _refScrollView.delegate = nil;
    _refScrollView = nil;
    _scrollViewDelegate = nil;
}

- (void)initWithScrollView:(UIScrollView*)scrollView Footer:(UIView<IFXRefreshViewProtocol>*)stateView{
    self.backgroundColor = [UIColor clearColor];
    
    _refScrollView = scrollView;
    _refScrollView.bounces=YES;
    _refScrollView.alwaysBounceVertical=YES;
    
    _refStateView = stateView;
    [self addSubview:_refStateView];
    
    FX_WEAK_REF_TYPE selfObject = self;
    [_refStateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(0));
        make.right.equalTo(selfObject.mas_right);
        make.top.equalTo(selfObject.mas_top);
        make.height.equalTo(@([_refStateView viewHeight]));
    }];
    
    self.state = FXRefreshStateNormal;
    
    [self initDelegate];
}

- (void)initDelegate{
    [[self rac_signalForSelector:@selector(scrollViewDidScroll:) fromProtocol:@protocol(UIScrollViewDelegate)] subscribeNext:^(RACTuple*tuple) {
        UIScrollView *scrollView = [tuple objectAtIndex:0];
        
        if (scrollView != _refScrollView) { return; }
        
        if ([self.scrollViewDelegate isFooterFullData]) {
            [self setState:FXRefreshStateFull];
        }else{
            if (_state == FXRefreshStateLoading && _isLoading) {
                CGFloat offset = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.size.height);
                offset = MIN(offset, 0);
                if (offset < 0) {
                    offset = MIN(offset * -1, [_refStateView viewHeight]);
                }
                scrollView.fx_contentInsetBottom = offset;
            } else if (scrollView.isDragging) {
                CGFloat space = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.size.height;
                
                if (_state == FXRefreshStatePulling && space >= -[_refStateView viewHeight] && !_isLoading) {
                    [self setState:FXRefreshStateNormal];
                } else if (_state == FXRefreshStateNormal && space < -[_refStateView viewHeight] && !_isLoading) {
                    [self setState:FXRefreshStatePulling];
                }
                if (scrollView.contentInset.bottom != 0) {
                    scrollView.fx_contentInsetBottom = 0.0f;
                }
            }
        }
        
        __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
        if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [strongDelegate scrollViewDidScroll:scrollView];
        }
    }];
    
    [[self rac_signalForSelector:@selector(scrollViewDidEndDragging:willDecelerate:) fromProtocol:@protocol(UIScrollViewDelegate)] subscribeNext:^(RACTuple*tuple) {
        UIScrollView *scrollView = [tuple objectAtIndex:0];
        BOOL decelerate = [[tuple objectAtIndex:1] boolValue];
        
        if (scrollView != _refScrollView) { return; }
        
        FX_WEAK_REF_TYPE selfObject = self;
        if (scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentSize.height >= [_refStateView viewHeight] && ![self.scrollViewDelegate isFooterFullData]) {
            _isLoading = [self.scrollViewDelegate refreshFooterDidTriggerRefresh:^(BOOL success) {
                if (scrollView.fx_contentInsetBottom != 0.0f) {
                    if (success) {
                        [selfObject setState:FXRefreshStateFinish];
                    } else {
                        [selfObject setState:FXRefreshStateFail];
                    }
                    _isLoading = NO;
                    [UIView animateWithDuration:0.25f delay:0.5f options:UIViewAnimationOptionTransitionNone animations:^{
                        selfObject.refScrollView.fx_contentInsetBottom = 0.0f;
                    } completion:^(BOOL finished) {
                        [selfObject setState:FXRefreshStateNormal];
                    }];
                }
            }];
            if (_isLoading) {
                [self setState:FXRefreshStateLoading];
                [UIView animateWithDuration:0.2f animations:^{
                    scrollView.fx_contentInsetBottom = [_refStateView viewHeight];
                }];
            }
        }
        
        __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
        
        if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
            [strongDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
        }
    }];
    
    _refScrollView.delegate = nil;
    _refScrollView.delegate = self;
}

- (void)setState:(FXRefreshState)state{
    if ([self.scrollViewDelegate isFooterFullData]) {
        [_refStateView refreshState:FXRefreshStateFull];
    }else{
        [_refStateView refreshState:state];
    }
    _state = state;
}

- (void)setRefreshDelegate:(NSObject<UIScrollViewDelegate,IFXRefreshDelegate> *)delegate{
    _scrollViewDelegate = delegate;
}

#pragma mark UIScrollViewDelegate
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    if (scrollView != _refScrollView) { return; }
//    
//
//    if ([self.scrollViewDelegate isFooterFullData]) {
//        [self setState:FXRefreshStateFull];
//    }else{
//        if (_state == FXRefreshStateLoading && _isLoading) {
//            CGFloat offset = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.size.height);
//            offset = MIN(offset, 0);
//            if (offset < 0) {
//                offset = MIN(offset * -1, [_refStateView viewHeight]);
//            }
//            scrollView.fx_contentInsetBottom = offset;
//        } else if (scrollView.isDragging) {
//            CGFloat space = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.size.height;
//            
//            if (_state == FXRefreshStatePulling && space >= -[_refStateView viewHeight] && !_isLoading) {
//                [self setState:FXRefreshStateNormal];
//            } else if (_state == FXRefreshStateNormal && space < -[_refStateView viewHeight] && !_isLoading) {
//                [self setState:FXRefreshStatePulling];
//            }
//            if (scrollView.contentInset.bottom != 0) {
//                scrollView.fx_contentInsetBottom = 0.0f;
//            }
//        }
//    }
//    
//    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
//    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
//        [strongDelegate scrollViewDidScroll:scrollView];
//    }
//}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [strongDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView NS_AVAILABLE_IOS(3_2){
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [strongDelegate scrollViewDidZoom:scrollView];
    }
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [strongDelegate scrollViewWillBeginDragging:scrollView];
    }
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0){
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [strongDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    if (scrollView != _refScrollView) { return; }
//    
//    FX_WEAK_REF_TYPE selfObject = self;
//    if (scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentSize.height >= [_refStateView viewHeight] && ![self.scrollViewDelegate isFooterFullData]) {
//        _isLoading = [self.scrollViewDelegate refreshFooterDidTriggerRefresh:^(BOOL success) {
//            if (scrollView.fx_contentInsetBottom != 0.0f) {
//                if (success) {
//                    [selfObject setState:FXRefreshStateFinish];
//                } else {
//                    [selfObject setState:FXRefreshStateFail];
//                }
//                _isLoading = NO;
//                [UIView animateWithDuration:0.25f delay:0.5f options:UIViewAnimationOptionTransitionNone animations:^{
//                    selfObject.refScrollView.fx_contentInsetBottom = 0.0f;
//                } completion:^(BOOL finished) {
//                    [selfObject setState:FXRefreshStateNormal];
//                }];
//            }
//        }];
//        if (_isLoading) {
//            [self setState:FXRefreshStateLoading];
//            [UIView animateWithDuration:0.2f animations:^{
//                scrollView.fx_contentInsetBottom = [_refStateView viewHeight];
//            }];
//        }
//    }
//    
//    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
//    
//    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
//        [strongDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
//    }
//}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [strongDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [strongDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return nil; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        return [strongDelegate viewForZoomingInScrollView:scrollView];
    }
    return nil;
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view NS_AVAILABLE_IOS(3_2){
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [strongDelegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale{
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [strongDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return NO; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [strongDelegate scrollViewShouldScrollToTop:scrollView];
    }
    return NO;
}
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [strongDelegate scrollViewDidScrollToTop:scrollView];
    }
}

@end
