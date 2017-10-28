//
//  NSObject+RLKVOWrapper.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLLiberation, RLStream;

@interface NSObject (RLKVOWrapper)

- (RLLiberation *)rl_observeKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(__weak NSObject *)observer block:(void (^)(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent))block;

- (RLStream *)rl_valuesForKeyPath:(NSString *)keyPath observer:(__weak NSObject *)observer;

- (RLStream *)rl_valuesAndChangesForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(__weak NSObject *)observer;

@end

#ifndef __RLOBSERVE__
#define __RLOBSERVE__
#define RLObserve(TARGET, KEYPATH) \
({ \
__weak id target_ = (TARGET); \
[target_ rl_valuesForKeyPath:@keypath(TARGET, KEYPATH) observer:self]; \
})
#endif
