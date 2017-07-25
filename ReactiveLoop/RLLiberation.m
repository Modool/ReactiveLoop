//
//  RLLiberation.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "RLLiberation.h"

@interface RLLiberation (){
    
    void * volatile _liberationBlock;
}

@end

@implementation RLLiberation

- (BOOL)isliberated {
    return _liberationBlock == NULL;
}

#pragma mark Lifecycle

- (instancetype)init {
    self = [super init];
    
    _liberationBlock = (__bridge void *)self;
    OSMemoryBarrier();
    
    return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
    NSCParameterAssert(block != nil);
    
    self = [super init];
    
    _liberationBlock = (void *)CFBridgingRetain([block copy]);
    OSMemoryBarrier();
    
    return self;
}

+ (instancetype)liberationWithBlock:(void (^)(void))block {
    return [[self alloc] initWithBlock:block];
}

- (void)dealloc {
    if (_liberationBlock == NULL || _liberationBlock == (__bridge void *)self) return;
    
    CFRelease(_liberationBlock);
    _liberationBlock = NULL;
}

#pragma mark Disposal

- (void)liberate {
    void (^liberationBlock)(void) = NULL;
    
    while (YES) {
        void *blockPtr = _liberationBlock;
        if (OSAtomicCompareAndSwapPtrBarrier(blockPtr, NULL, &_liberationBlock)) {
            if (blockPtr != (__bridge void *)self) {
                liberationBlock = CFBridgingRelease(blockPtr);
            }
            
            break;
        }
    }
    
    if (liberationBlock != nil) liberationBlock();
}

#pragma mark Scoped Liberations

- (RLScopedLiberation *)asScopedLiberation {
    return [RLScopedLiberation scopedWithLiberation:self];
}


@end

@implementation RLScopedLiberation

+ (instancetype)scopedWithLiberation:(RLLiberation *)liberation {
    return [self liberationWithBlock:^{
        [liberation liberate];
    }];
}

- (void)dealloc {
    [self liberate];
}

#pragma mark RLLiberation

- (RLScopedLiberation *)asScopedLiberation {
    return self;
}

@end
