//
//  RLEvent.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLEvent.h"
#import "RLObserver+Private.h"
#import "RLLiberation.h"

#import "RLEXTScope.h"

@interface RLEvent ()

@property (nonatomic, strong, readonly) NSMutableArray<RLObserver> *observers;

@property (nonatomic, strong, readonly) RLCompoundLiberation *liberation;

- (void)enumerateObserversUsingBlock:(void (^)(id<RLObserver> observer))block;

@end

@implementation RLEvent

+ (instancetype)event; {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _observers = [[NSMutableArray<RLObserver> alloc] init];
        _liberation = [RLCompoundLiberation compoundLiberation];
    }
    return self;
}

- (void)dealloc {
    [[self liberation] liberate];
}

- (RLLiberation *)observe:(id<RLObserver>)observer {
    NSCParameterAssert(observer != nil);
    
    RLCompoundLiberation *liberation = [RLCompoundLiberation compoundLiberation];
    observer = [[RLPassthroughObserver alloc] initWithObserver:observer stream:self liberation:liberation];
    
    NSMutableArray *observers = self.observers;
    @synchronized (observers) {
        [observers addObject:observer];
    }
    [liberation addLiberation:[RLLiberation liberationWithBlock:^{
        @synchronized (observers) {
            // Since newer observers are generally shorter-lived, search
            // starting from the end of the list.
            NSUInteger index = [observers indexOfObjectWithOptions:NSEnumerationReverse passingTest:^ BOOL (id<RLObserver> obj, NSUInteger index, BOOL *stop) {
                return obj == observer;
            }];
            if (index != NSNotFound) [observers removeObjectAtIndex:index];
        }
    }]];
    return liberation;
}

- (void)enumerateObserversUsingBlock:(void (^)(id<RLObserver> observer))block {
    NSArray *observers;
    @synchronized (self.observers) {
        observers = [self.observers copy];
    }
    
    for (id<RLObserver> observer in observers) {
        block(observer);
    }
}

- (void)output:(nullable id)value; {
    [self enumerateObserversUsingBlock:^(id<RLObserver> observer) {
        [observer output:value];
    }];
}

- (void)complete;{
    [[self liberation] liberate];
    
    [self enumerateObserversUsingBlock:^(id<RLObserver> observer) {
        [observer complete];
    }];
}

- (void)didObserveWithLiberation:(RLCompoundLiberation *)liberation{
    if (liberation.liberated) return;
    [self.liberation addLiberation:liberation];
    
    @weakify(self, liberation);
    [liberation addLiberation:[RLLiberation liberationWithBlock:^{
        @strongify(self, liberation);
        [self.liberation removeLiberation:liberation];
    }]];
}

@end

@interface RLReplayEvent ()

@property (nonatomic, strong) id receivedValue;

@property (nonatomic, assign, getter=isCompleted) BOOL completed;

@end

@implementation RLReplayEvent

#pragma mark RLStream

- (RLLiberation *)observe:(id<RLObserver>)observer {
    RLCompoundLiberation *compoundLiberation = [RLCompoundLiberation compoundLiberation];
    
    RLLiberation *liberation = [RLLiberation liberationWithBlock:^{
        @synchronized (self) {
            if (compoundLiberation.liberated) return;
            
            [observer output:[self receivedValue]];
            
            if (self.completed) {
                [observer complete];
            } else {
                RLLiberation *subscriptionLiberation = [super observe:observer];
                [compoundLiberation addLiberation:subscriptionLiberation];
            }
        }
    }];
    
    [compoundLiberation addLiberation:liberation];
    
    return compoundLiberation;
}

#pragma mark RLSubscriber

- (void)output:(id)value{
    @synchronized (self) {
        self.receivedValue = value;
        [super output:value];
    }
}

- (void)complete {
    @synchronized (self) {
        self.completed = YES;
        [super complete];
    }
}


@end
