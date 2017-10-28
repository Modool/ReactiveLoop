//
//  RLObserver.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLStream, RLCompoundLiberation, RLLiberation;

@protocol RLObserver <NSObject>

- (void)output:(nullable id)value;

- (void)complete;

- (void)didObserveWithLiberation:(RLCompoundLiberation *)liberation;

@end

NS_ASSUME_NONNULL_END
