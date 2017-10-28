//
//  NSObject+RLDeallocating.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLCompoundLiberation;
@class RLLiberation;
@class RLStream;

@interface NSObject (RLDeallocating)

@property (atomic, readonly, strong) RLCompoundLiberation *rl_deallocLiberation;

- (RLStream *)rl_willDeallocStream;

@end

NS_ASSUME_NONNULL_END
