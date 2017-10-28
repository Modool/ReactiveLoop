//
//  RLObserver.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLObserver.h"
#import "RLObserver+Private.h"
#import "RLLiberation.h"

#import "RLEXTScope.h"

@interface RLObserver ()

@property (nonatomic, copy) void (^output)(id value);
@property (nonatomic, copy) void (^completion)();

@property (nonatomic, strong, readonly) RLCompoundLiberation *liberation;

@end

@implementation RLObserver

+ (instancetype)observerWithOutput:(void (^)(id value))output completion:(void (^)())completion; {
    return [[self alloc] initWithOutput:output completion:completion];
}

- (instancetype)init{
    return [self initWithOutput:nil completion:nil];
}

- (instancetype)initWithOutput:(void (^)(id value))output completion:(void (^)())completion; {
    if (self = [super init]) {
        self.output = output;
        self.completion = completion;
        
        @unsafeify(self);
        RLLiberation *selfLiberation = [RLLiberation liberationWithBlock:^{
            @strongify(self);
            @synchronized (self) {
                self.output = nil;
                self.completion = nil;
            }
        }];
        
        _liberation = [RLCompoundLiberation compoundLiberation];
        [_liberation addLiberation:selfLiberation];
    }
    return self;
}

- (void)dealloc {
    [[self liberation] liberate];
}

- (void)output:(nullable id)value;{
    @synchronized (self) {
        void (^output)(id) = [[self output] copy];
        
        if (output == nil) return;
        output(value);
    }
}

- (void)complete{
    @synchronized (self) {
        void (^completion)(void) = [self.completion copy];

        [self.liberation liberate];
        if (completion == nil) return;
        completion();
    }
}
- (void)didObserveWithLiberation:(RLCompoundLiberation *)liberation;{
    if (liberation.liberated) return;
    
    RLCompoundLiberation *selfLiberation = self.liberation;
    [selfLiberation addLiberation:liberation];
    
    @unsafeify(liberation);
    [liberation addLiberation:[RLLiberation liberationWithBlock:^{
        @strongify(liberation);
        [selfLiberation removeLiberation:liberation];
    }]];
}

@end

@interface RLPassthroughObserver ()

@property (nonatomic, strong, readonly) id<RLObserver> innerObserver;

@property (nonatomic, unsafe_unretained, readonly) RLStream *stream;

@property (nonatomic, strong, readonly) RLCompoundLiberation *liberation;

@end

@implementation RLPassthroughObserver

#pragma mark Lifecycle

- (instancetype)initWithObserver:(id<RLObserver>)observer stream:(RLStream *)stream liberation:(RLCompoundLiberation *)liberation; {
    NSCParameterAssert(observer);
    if (self = [super init]) {
        _innerObserver = observer;
        _stream = stream;
        _liberation = liberation;
        
        [[self innerObserver] didObserveWithLiberation:self.liberation];
    }
    return self;
}

#pragma mark RLObserver

- (void)output:(nullable id)value; {
    if (self.liberation.liberated) return;
    
    [self.innerObserver output:value];
}

- (void)complete {
    if (self.liberation.liberated) return;
    
    [self.innerObserver complete];
}

- (void)didObserveWithLiberation:(RLCompoundLiberation *)liberation;{
    if (liberation != self.liberation) {
        [self.liberation addLiberation:liberation];
    }
}

@end
