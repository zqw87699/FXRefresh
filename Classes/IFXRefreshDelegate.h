//
//  IFXRefreshDelegate.h
//  TTTT
//
//  Created by 张大宗 on 2017/3/3.
//  Copyright © 2017年 张大宗. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IFXRefreshDelegate <NSObject>

@optional

/*
 *  是否刷新(如果是，block传值)
 */
- (BOOL)refreshHeaderDidTriggerRefresh:(void(^)(BOOL success))block;

/*
 *  是否刷新(如果是，block传值)
 */
- (BOOL)refreshFooterDidTriggerRefresh:(void(^)(BOOL success))block;

/*
 *  是否有数据
 */
- (BOOL)isHeaderFullData;

/*
 *  是否有数据
 */
- (BOOL)isFooterFullData;

@end
