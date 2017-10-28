//
//  RLLiberation.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import <pthread/pthread.h>
#import <CoreFoundation/CoreFoundation.h>

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

@interface RLCompoundLiberation () {
    pthread_mutex_t _mutex;
    NSMutableArray *_liberations;
    
    BOOL _liberated;
}

@end

@implementation RLCompoundLiberation

#pragma mark Properties

- (BOOL)isLiberated {
    pthread_mutex_lock(&_mutex);
    BOOL liberated = _liberated;
    pthread_mutex_unlock(&_mutex);
    
    return liberated;
}

#pragma mark Lifecycle

+ (instancetype)compoundLiberation {
    return [[self alloc] initWithLiberations:nil];
}

+ (instancetype)compoundLiberationWithLiberations:(NSArray *)liberations {
    return [[self alloc] initWithLiberations:liberations];
}

- (instancetype)init {
    self = [super init];
    
    const int result __attribute__((unused)) = pthread_mutex_init(&_mutex, NULL);
    NSCAssert(0 == result, @"Failed to initialize mutex with error %d.", result);
    
    return self;
}

- (instancetype)initWithLiberations:(NSArray *)otherLiberations {
    if (self = [self init]) {
        _liberations = [otherLiberations ?: @[] mutableCopy];
    }
    return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
    RLLiberation *liberation = [RLLiberation liberationWithBlock:block];
    return [self initWithLiberations:@[ liberation ]];
}

- (void)dealloc {
    if (_liberations) {
        _liberations = nil;
    }
    const int result __attribute__((unused)) = pthread_mutex_destroy(&_mutex);
    NSCAssert(0 == result, @"Failed to destroy mutex with error %d.", result);
}

- (void)liberate {
    NSArray *remainingLiberations = nil;
    pthread_mutex_lock(&_mutex);
    {
        _liberated = YES;
        
        remainingLiberations = [_liberations copy];
        _liberations = NULL;
    }
    pthread_mutex_unlock(&_mutex);
    
    if (!remainingLiberations) return;
    for (RLLiberation *liberation in remainingLiberations) {
        [liberation liberate];
    }
}
#pragma mark Addition and Removal

- (void)addLiberation:(RLLiberation *)liberation {
    NSCParameterAssert(liberation != self);
    if (!liberation || liberation.liberated) return;
    
    BOOL shouldLiberate = NO;
    
    pthread_mutex_lock(&_mutex);
    {
        if (_liberated) {
            shouldLiberate = YES;
        } else {
            if (!_liberations) _liberations = [NSMutableArray new];
            
            [_liberations addObject:liberation];
        }
    }
    pthread_mutex_unlock(&_mutex);
    
    // Performed outside of the lock in case the compound liberation is used
    // recursively.
    if (shouldLiberate) [liberation liberate];
}

- (void)removeLiberation:(RLLiberation *)liberation {
    if (!liberation) return;
    
    pthread_mutex_lock(&_mutex);
    {
        if (!_liberated && _liberations) {
            [_liberations removeObject:liberation];
        }
    }
    pthread_mutex_unlock(&_mutex);
}

@end

@interface RLSerialLiberation () {
    RLLiberation * _liberation;
    
    BOOL _liberated;
    
    pthread_mutex_t _mutex;
}

@end

@implementation RLSerialLiberation

#pragma mark Properties

- (BOOL)isDisposed {
    pthread_mutex_lock(&_mutex);
    const BOOL liberated = _liberated;
    pthread_mutex_unlock(&_mutex);
    
    return liberated;
}

- (RLLiberation *)liberation {
    pthread_mutex_lock(&_mutex);
    RLLiberation * const result = _liberation;
    pthread_mutex_unlock(&_mutex);
    
    return result;
}

- (void)setLiberation:(RLLiberation *)liberation {
    [self swapInLiberation:liberation];
}

#pragma mark Lifecycle

+ (instancetype)serialLiberationWithLiberation:(RLLiberation *)liberation {
    RLSerialLiberation *serialLiberation = [[self alloc] init];
    serialLiberation.liberation = liberation;
    return serialLiberation;
}

- (instancetype)init {
    self = [super init];
    if (self == nil) return nil;
    
    const int result __attribute__((unused)) = pthread_mutex_init(&_mutex, NULL);
    NSCAssert(0 == result, @"Failed to initialize mutex with error %d", result);
    
    return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
    self = [self init];
    if (self == nil) return nil;
    
    self.liberation = [RLLiberation liberationWithBlock:block];
    
    return self;
}

- (void)dealloc {
    const int result __attribute__((unused)) = pthread_mutex_destroy(&_mutex);
    NSCAssert(0 == result, @"Failed to destroy mutex with error %d", result);
}

#pragma mark Inner Liberation

- (RLLiberation *)swapInLiberation:(RLLiberation *)newLiberation {
    RLLiberation *existingLiberation;
    BOOL alreadyDisposed;
    
    pthread_mutex_lock(&_mutex);
    alreadyDisposed = _liberated;
    if (!alreadyDisposed) {
        existingLiberation = _liberation;
        _liberation = newLiberation;
    }
    pthread_mutex_unlock(&_mutex);
    
    if (alreadyDisposed) {
        [newLiberation liberate];
        return nil;
    }
    
    return existingLiberation;
}

#pragma mark Disposal

- (void)liberate {
    RLLiberation *existingLiberation;
    
    pthread_mutex_lock(&_mutex);
    if (!_liberated) {
        existingLiberation = _liberation;
        _liberated = YES;
        _liberation = nil;
    }
    pthread_mutex_unlock(&_mutex);
    
    [existingLiberation liberate];
}

@end
