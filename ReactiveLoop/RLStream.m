//
//  RLStream.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <libkern/OSAtomic.h>

#import "RLStream.h"
#import "RLStream+Private.h"
#import "RLObserver+Private.h"
#import "RLLiberation.h"

@implementation RLStream

- (instancetype)init {
    self = [super init];
    
    self.name = @"";
    return self;
}

- (instancetype)setNameWithFormat:(NSString *)format, ... {
    NSCParameterAssert(format != nil);
    
    va_list args;
    va_start(args, format);
    
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    self.name = str;
    return self;
}

+ (__kindof RLStream *)create:(RLLiberation * (^)(id<RLObserver> observer))observeCompletion; {
    return [RLDynamicStream create:observeCompletion];
}

+ (__kindof RLStream *)never {
    return [[self create:^ RLLiberation * (id<RLObserver> observer) {
        return nil;
    }] setNameWithFormat:@"+never"];
}

+ (__kindof RLStream *)empty {
    return [RLEmptyStream empty];
}

+ (__kindof RLStream *)return:(id)value {
    return [RLReturnStream return:value];
}

- (__kindof RLStream *)bind:(RLStreamBindBlock (^)(void))block {
    NSCParameterAssert(block);
    return [[RLStream create:^(id<RLObserver> observer) {
        __block volatile int32_t streamCount = 1;   // indicates self
        
        RLStreamBindBlock bindingBlock = block();
        RLCompoundLiberation *compoundLiberation = [RLCompoundLiberation compoundLiberation];
        
        void (^completeStream)(RLLiberation *) = ^(RLLiberation *finishedLiberation) {
            if (OSAtomicDecrement32Barrier(&streamCount) == 0) {
                [compoundLiberation liberate];
            } else {
                [compoundLiberation removeLiberation:finishedLiberation];
            }
        };
        void (^addStream)(RLStream *) = ^(RLStream *stream) {
            OSAtomicIncrement32Barrier(&streamCount);
            
            RLSerialLiberation *selfLiberation = [RLSerialLiberation new];
            [compoundLiberation addLiberation:selfLiberation];
            
            RLLiberation *liberation = [stream observeOutput:^(id  _Nonnull value) {
                [observer output:value];
            }];
            selfLiberation.liberation = liberation;
        };
        @autoreleasepool {
            RLSerialLiberation *selfLiberation = [RLSerialLiberation new];
            [compoundLiberation addLiberation:selfLiberation];
            
            RLLiberation *bindingLiberation = [self observeOutput:^(id value) {
                if (compoundLiberation.liberated) return;
                
                BOOL stop = NO;
                id stream = bindingBlock(value, &stop);
                
                @autoreleasepool {
                    if (stream) addStream(stream);
                    if (!stream || stop) {
                        [selfLiberation liberate];
                        completeStream(selfLiberation);
                    }
                }
            }];
            selfLiberation.liberation = bindingLiberation;
        }
        return compoundLiberation;
    }] setNameWithFormat:@"[%@] -bind:", self.name];
}

- (__kindof RLStream *)flattenMap:(__kindof RLStream * (^)(id value))block {
    Class class = self.class;
    
    return [[self bind:^{
        return ^(id value, BOOL *stop) {
            id stream = block(value) ?: [class empty];
            NSCAssert([stream isKindOfClass:RLStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);
            
            return stream;
        };
    }] setNameWithFormat:@"[%@] -flattenMap:", self.name];
}

- (__kindof RLStream *)flatten {
    return [[self flattenMap:^(id value) {
        return value;
    }] setNameWithFormat:@"[%@] -flatten", self.name];
}

- (__kindof RLStream *)map:(id (^)(id value))block {
    NSCParameterAssert(block != nil);
    
    Class class = self.class;
    
    return [[self flattenMap:^(id value) {
        return [class return:block(value)];
    }] setNameWithFormat:@"[%@] -map:", self.name];
}

- (__kindof RLStream *)mapReplace:(id)object {
    return [[self map:^(id x) {
        return object;
    }] setNameWithFormat:@"[%@] -mapReplace: %@", self.name, object];
}

- (__kindof RLStream *)filter:(BOOL (^)(id value))block {
    NSCParameterAssert(block != nil);
    
    Class class = self.class;
    
    return [[self flattenMap:^ id (id value) {
        if (block(value)) {
            return [class return:value];
        } else {
            return class.empty;
        }
    }] setNameWithFormat:@"[%@] -filter:", self.name];
}

- (__kindof RLStream *)ignore:(id)value {
    return [[self filter:^ BOOL (id innerValue) {
        return innerValue != value && ![innerValue isEqual:value];
    }] setNameWithFormat:@"[%@] -ignore: %@", self.name, value];
}

- (__kindof RLStream *)ignore {
    return [[self filter:^ BOOL (id innerValue) {
        return NO;
    }] setNameWithFormat:@"[%@] -ignore", self.name];
}

+ (__kindof RLStream *)join:(id<NSFastEnumeration>)streams block:(RLStream * (^)(id, id))block {
    RLStream *current = nil;
    
    for (RLStream *stream in streams) {
        if (!current) {
            current = [stream map:^id (id x) {
                return @[x ?: NSNull.null];
            }];
            continue;
        }
        current = block(current, stream);
    }
    
    if (!current) return [self empty];
    
    return [current map:^id (NSArray *values) {
        NSMutableArray *innerValues = [NSMutableArray new];
        while (values) {
            [innerValues insertObject:values.lastObject ?: NSNull.null atIndex:0];
            values = (values.count > 1 ? values.firstObject : nil);
        }
        return innerValues;
    }];
}

- (__kindof RLStream *)zipWith:(RLStream *)stream {
    NSCParameterAssert(stream != nil);
    
    return [[RLStream create:^RLLiberation *(id<RLObserver> observer) {
        __block BOOL selfCompleted = NO;
        NSMutableArray *selfValues = [NSMutableArray array];
        
        __block BOOL otherCompleted = NO;
        NSMutableArray *otherValues = [NSMutableArray array];
        
        void (^completeIfNecessary)(void) = ^{
            @synchronized (selfValues) {
                BOOL selfEmpty = (selfCompleted && selfValues.count == 0);
                BOOL otherEmpty = (otherCompleted && otherValues.count == 0);
                if (selfEmpty || otherEmpty) [observer complete];
            }
        };
        
        void (^output)(void) = ^{
            @synchronized (selfValues) {
                if (selfValues.count == 0) return;
                if (otherValues.count == 0) return;
                
                NSArray *values = @[selfValues[0], otherValues[0]];
                [selfValues removeObjectAtIndex:0];
                [otherValues removeObjectAtIndex:0];
                
                [observer output:values];
                completeIfNecessary();
            }
        };
        
        RLLiberation *selfLiberation = [self observeOutput:^(id value) {
            @synchronized (selfValues) {
                [selfValues addObject:value ?: NSNull.null];
                output();
            }
        } completion:^{
            @synchronized (selfValues) {
                selfCompleted = YES;
                completeIfNecessary();
            }
        }];
        
        RLLiberation *otherLiberation = [stream observeOutput:^(id value) {
            @synchronized (selfValues) {
                [otherValues addObject:value ?: NSNull.null];
                output();
            }
        } completion:^{
            @synchronized (selfValues) {
                otherCompleted = YES;
                completeIfNecessary();
            }
        }];
        
        return [RLLiberation liberationWithBlock:^{
            [selfLiberation liberate];
            [otherLiberation liberate];
        }];
    }] setNameWithFormat:@"[%@] -zipWith: %@", self.name, stream];
}

+ (__kindof RLStream *)zip:(id<NSFastEnumeration>)streams {
    return [[self join:streams block:^(RLStream *left, RLStream *right) {
        return [left zipWith:right];
    }] setNameWithFormat:@"+zip: %@", streams];
}

- (__kindof RLStream *)takeUntil:(RLStream *)streamTrigger {
    return [[RLStream create:^(id<RLObserver> observer) {
        RLCompoundLiberation *liberation = [RLCompoundLiberation compoundLiberation];
        void (^triggerCompletion)(void) = ^{
            [liberation liberate];
            [observer complete];
        };
        RLLiberation *triggerLiberation = [streamTrigger observeOutput:^(id value) {
            triggerCompletion();
        } completion:^{
            triggerCompletion();
        }];
        [liberation addLiberation:triggerLiberation];
        
        if (!liberation.liberated) {
            RLLiberation *selfLiberation = [self observeOutput:^(id value) {
                [observer output:value];
            } completion:^{
                [liberation liberate];
                [observer complete];
            }];
            [liberation addLiberation:selfLiberation];
        }
        return liberation;
    }] setNameWithFormat:@"[%@] -takeUntil: %@", self.name, streamTrigger];
}

- (__kindof RLStream *)combineLatestWith:(RLStream *)stream {
    NSCParameterAssert(stream != nil);
    
    return [[RLStream create:^(id<RLObserver> observer) {
        RLCompoundLiberation *liberation = [RLCompoundLiberation compoundLiberation];
        
        __block id lastSelfValue = nil;
        __block BOOL selfCompleted = NO;
        
        __block id lastOtherValue = nil;
        __block BOOL otherCompleted = NO;
        
        void (^output)(void) = ^{
            @synchronized (liberation) {
                if (lastSelfValue == nil || lastOtherValue == nil) return;
                [observer output:@[lastSelfValue, lastOtherValue]];
            }
        };
        
        RLLiberation *selfLiberation = [self observeOutput:^(id x) {
            @synchronized (liberation) {
                lastSelfValue = x ?: NSNull.null;
                output();
            }
        } completion:^{
            @synchronized (liberation) {
                selfCompleted = YES;
                if (otherCompleted) [observer complete];
            }
        }];
        
        [liberation addLiberation:selfLiberation];
        
        RLLiberation *otherLiberation = [stream observeOutput:^(id x) {
            @synchronized (liberation) {
                lastOtherValue = x ?: NSNull.null;
                output();
            }
        } completion:^{
            @synchronized (liberation) {
                otherCompleted = YES;
                if (selfCompleted) [observer complete];
            }
        }];
        
        [liberation addLiberation:otherLiberation];
        
        return liberation;
    }] setNameWithFormat:@"[%@] -combineLatestWith: %@", self.name, stream];
}

+ (__kindof RLStream *)combineLatest:(id<NSFastEnumeration>)signals {
    return [[self join:signals block:^(RLStream *left, RLStream *right) {
        return [left combineLatestWith:right];
    }] setNameWithFormat:@"+combineLatest: %@", signals];
}

- (__kindof RLStream *)merge:(RLStream *)stream {
    return [[RLStream merge:@[ self, stream ]] setNameWithFormat:@"[%@] -merge: %@", self.name, stream];
}

+ (__kindof RLStream *)merge:(id<NSFastEnumeration>)streams {
    NSMutableArray *copiedStreams = [[NSMutableArray alloc] init];
    for (RLStream *stream in streams) {
        [copiedStreams addObject:stream];
    }
    return [[[RLStream create:^ RLLiberation * (id<RLObserver> observer) {
                  for (RLStream *stream in copiedStreams) {
                      [observer output:stream];
                  }
                  [observer complete];
                  return nil;
              }] flatten] setNameWithFormat:@"+merge: %@", copiedStreams];
}

- (__kindof RLStream *)doOutput:(void (^)(id value))block {
    NSCParameterAssert(block != NULL);
    
    return [[RLStream create:^RLLiberation *(id<RLObserver> observer) {
        return [self observeOutput:^(id  _Nonnull value) {
            block(value);
            [observer output:value];
        } completion:^{
            [observer complete];
        }];
    }] setNameWithFormat:@"[%@] -doOutput:", self.name];
}

- (__kindof RLStream *)doComplet:(void (^)(void))block {
    NSCParameterAssert(block != NULL);
    
    return [[RLStream create:^RLLiberation *(id<RLObserver> observer) {
        return [self observeOutput:^(id  _Nonnull value) {
            [observer output:value];
        } completion:^{
            block();
            [observer complete];
        }];
    }] setNameWithFormat:@"[%@] -doOver:", self.name];
}

- (RLLiberation *)observe:(id<RLObserver>)observe {
    NSCAssert(NO, @"This method must be overridden by subclasses");
    return nil;
}

- (RLLiberation *)observeOutput:(void (^)(id value))output {
    NSCParameterAssert(output != NULL);
    
    RLObserver *observer = [RLObserver observerWithOutput:output completion:nil];
    return [self observe:observer];
}

- (RLLiberation *)observeOutput:(void (^)(id value))output completion:(void (^)())completion;{
    NSCParameterAssert(output != NULL);
    NSCParameterAssert(completion != NULL);
    
    RLObserver *observer = [RLObserver observerWithOutput:output completion:completion];
    return [self observe:observer];
}

@end

@implementation RLEmptyStream

- (void)setName:(NSString *)name {
    [super setName:@"+empty"];
}

- (NSString *)name {
    return @"+empty";
}

#pragma mark Lifecycle

+ (RLStream *)empty {
    static RLEmptyStream *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [self new];
    });
    
    return singleton;
}

- (RLLiberation *)observe:(id<RLObserver>)observe; {
    NSCParameterAssert(observe != nil);
    [observe complete];
    
    return nil;
}

@end

@interface RLReturnStream ()

// The value to send upon subscription.
@property (nonatomic, strong) id value;

@end

@implementation RLReturnStream

- (instancetype)initWithValue:(id)value{
    if (self = [super init]) {
        self.value = value;
    }
    return self;
}

- (void)setName:(NSString *)name {
    [super setName:@"+return:"];
}

- (NSString *)name {
    return @"+return:";
}

+ (RLStream *)return:(id)value {
    return [[self alloc] initWithValue:value];;
}

- (RLLiberation *)observe:(id<RLObserver>)observer{
    NSCParameterAssert(observer);
    
    [observer output:[self value]];
    [observer complete];
    
    return nil;
}

@end

@interface RLDynamicStream ()

@property (nonatomic, copy) RLLiberation * (^observeCompletion)(id<RLObserver> observer);

@end

@implementation RLDynamicStream

+ (RLStream *)create:(RLLiberation * (^)(id<RLObserver> observer))observeCompletion;{
    return [[[self alloc] initWithObserveCompletion:observeCompletion] setNameWithFormat:@"+createStream:"];
}

- (instancetype)initWithObserveCompletion:(RLLiberation * (^)(id<RLObserver> observer))observeCompletion;{
    if (self = [super init]) {
        self.observeCompletion = observeCompletion;
    }
    return self;
}

#pragma mark Managing Observers

- (RLLiberation *)observe:(id<RLObserver>)observer {
    NSCParameterAssert(observer);
    RLCompoundLiberation *liberation = [RLCompoundLiberation compoundLiberation];
    if (self.observeCompletion) {
        RLLiberation *innerLiberation = self.observeCompletion(observer);
        [liberation addLiberation:innerLiberation];
    }
    return liberation;
}

@end
