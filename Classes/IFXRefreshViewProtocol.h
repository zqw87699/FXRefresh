//
//  IFXRefreshViewProtocol.h
//  TTTT
//
//  Created by 张大宗 on 2017/3/3.
//  Copyright © 2017年 张大宗. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,FXRefreshState) {
    /*
     *  无
     */
    FXRefreshStateNone = 0,
    
    /*
     *  拉动状态
     */
    FXRefreshStatePulling = 1,
    
    /*
     *  正常状态
     */
    FXRefreshStateNormal = 2,
    
    /*
     *  加载状态
     */
    FXRefreshStateLoading = 3,
    
    /*
     *  加载成功
     */
    FXRefreshStateFinish = 4,
    
    /*
     *  加载失败
     */
    FXRefreshStateFail = 5,
    
    /*
     *  加载完成
     */
    FXRefreshStateFull = 6,
};

@protocol IFXRefreshViewProtocol <NSObject>

- (void) refreshState:(FXRefreshState) state;

- (CGFloat) viewHeight;

@end
