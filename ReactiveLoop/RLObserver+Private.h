//
//  RLObserver+Private.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLObserver.h"
#import "RLStream.h"
#import "RLLiberation.h"

@interface RLObserver : NSObject<RLObserver>

+ (instancetype)observerWithOutput:(void (^)(id value))output completion:(void (^)(void))completion;
- (instancetype)initWithOutput:(void (^)(id value))output completion:(void (^)(void))completion NS_DESIGNATED_INITIALIZER;

@end

@interface RLPassthroughObserver : NSObject <RLObserver>

- (instancetype)initWithObserver:(id<RLObserver>)observer stream:(RLStream *)stream liberation:(RLCompoundLiberation *)liberation;

@end
