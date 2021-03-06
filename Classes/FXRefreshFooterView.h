//
//  FXRefreshFooterView.h
//  TTTT
//
//  Created by 张大宗 on 2017/3/3.
//  Copyright © 2017年 张大宗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IFXRefreshDelegate.h"
#import "IFXRefreshViewProtocol.h"

@interface FXRefreshFooterView : UIView<UIScrollViewDelegate>

+ (instancetype) refreshForScrollView:(UIScrollView*)scrollView Footer:(UIView<IFXRefreshViewProtocol>*)stateView;

- (void)setRefreshDelegate:(NSObject<UIScrollViewDelegate,IFXRefreshDelegate>*)delegate;

@end
