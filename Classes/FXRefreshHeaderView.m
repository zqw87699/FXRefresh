//
//  FXRefreshHeaderView.m
//  TTTT
//
//  Created by 张大宗 on 2017/3/3.
//  Copyright © 2017年 张大宗. All rights reserved.
//

#import "FXRefreshHeaderView.h"
#import "FXCommon.h"
#import "UIScrollView+FXExtension.h"
#import "Masonry.h"

@interface FXRefreshHeaderView()

@property (nonatomic,weak) UIScrollView *refScrollView;

@property (nonatomic,weak) NSObject<UIScrollViewDelegate,IFXRefreshDelegate>* scrollViewDelegate;

@property (nonatomic,assign) FXRefreshState state;

@property (nonatomic,strong) UIView<IFXRefreshViewProtocol> *refStateView;

@property (nonatomic,assign) BOOL isLoading;

@end

@implementation FXRefreshHeaderView

+ (instancetype)refreshForScrollView:(UIScrollView *)scrollView Header:(UIView<IFXRefreshViewProtocol> *)stateView{
    FXRefreshHeaderView*headerView = [[FXRefreshHeaderView alloc] init];
    if (headerView) {
        [scrollView addSubview:headerView];
        [headerView setFrame:CGRectMake(0, -scrollView.frame.size.height, scrollView.frame.size.width, scrollView.frame.size.height)];
        [headerView initWithScrollView:scrollView Header:stateView];
    }
    return headerView;
}

- (void)dealloc {
    _refScrollView.delegate = nil;
    _refScrollView = nil;
    _scrollViewDelegate = nil;
}

- (void)initWithScrollView:(UIScrollView*)scrollView Header:(UIView<IFXRefreshViewProtocol>*)stateView{
    
    self.backgroundColor = [UIColor clearColor];
    
    _refScrollView = scrollView;
    _refScrollView.bounces=YES;
    _refScrollView.alwaysBounceVertical=YES;
    _refScrollView.delegate = self;
    
    _refStateView = stateView;
    [self addSubview:_refStateView];
    
    FX_WEAK_REF_TYPE selfObject = self;
    [_refStateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(0));
        make.right.equalTo(selfObject.mas_right);
        make.bottom.equalTo(selfObject.mas_bottom);
        make.height.equalTo(@([_refStateView viewHeight]));
    }];
    
    self.state = FXRefreshStateNormal;
}

- (void)setState:(FXRefreshState)state{
    if ([self.delegate isHeaderFullData]) {
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
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView != _refScrollView) { return; }
    
    if ([self.delegate isHeaderFullData]) {
        [self setState:FXRefreshStateFull];
    }else{
        if (_state == FXRefreshStateLoading && _isLoading) {
            CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
            offset = MIN(offset, [_refStateView viewHeight]);
            scrollView.fx_contentInsetTop = offset;
        } else if (scrollView.isDragging) {
            if (_state == FXRefreshStatePulling && scrollView.contentOffset.y > -[_refStateView viewHeight] && scrollView.contentOffset.y < 0.0f && !_isLoading) {
                [self setState:FXRefreshStateNormal];
            } else if (_state == FXRefreshStateNormal && scrollView.contentOffset.y < -[_refStateView viewHeight] && !_isLoading) {
                [self setState:FXRefreshStatePulling];
            }
            
            if (scrollView.contentInset.top != 0) {
                scrollView.fx_contentInsetTop = 0.0f;
            }
        }
    }

    
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [strongDelegate scrollViewDidScroll:scrollView];
    }
}

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
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (scrollView != _refScrollView) { return; }
    
    FX_WEAK_REF_TYPE selfObject = self;
    if (scrollView.contentOffset.y <= -[_refStateView viewHeight] && !_isLoading && ![self.delegate isHeaderFullData]) {
        _isLoading = [self.delegate refreshHeaderDidTriggerRefresh:^(BOOL success) {
            if (scrollView.fx_contentInsetTop != 0.0f) {
                if (success) {
                    [selfObject setState:FXRefreshStateFinish];
                } else {
                    [selfObject setState:FXRefreshStateFail];
                }
                _isLoading = NO;
                [UIView animateWithDuration:0.25f delay:0.5f options:UIViewAnimationOptionTransitionNone animations:^{
                    selfObject.refScrollView.fx_contentInsetTop = 0.0f;
                } completion:^(BOOL finished) {
                    [selfObject setState:FXRefreshStateNormal];
                }];
            }else {
                _isLoading = NO;
                [selfObject setState:FXRefreshStateNormal];
            }
        }];
        if (_isLoading) {
            [self setState:FXRefreshStateLoading];
            [UIView animateWithDuration:0.2f animations:^{
                selfObject.refScrollView.fx_contentInsetTop = [_refStateView viewHeight];
            }];
        }
    }
    
    __strong NSObject<UIScrollViewDelegate>* strongDelegate = _scrollViewDelegate;
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [strongDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}
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
