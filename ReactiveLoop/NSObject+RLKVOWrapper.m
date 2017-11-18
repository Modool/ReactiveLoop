//
//  NSObject+RLKVOWrapper.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "NSObject+RLKVOWrapper.h"
#import "NSObject+RLDeallocating.h"

#import "RLStream.h"
#import "RLObserver.h"
#import "RLLiberation.h"

#import "RLEXTRuntimeExtensions.h"
#import "RLEXTScope.h"

typedef void (^RLKVOBlock)(id target, id observer, NSDictionary *change);

@interface RLKVOProxy : NSObject
@end

@interface RLKVOProxy()

@property (strong, nonatomic, readonly) NSMapTable *trampolines;
@property (strong, nonatomic, readonly) dispatch_queue_t queue;

@end

@implementation RLKVOProxy

+ (instancetype)sharedProxy {
    static RLKVOProxy *proxy;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        proxy = [[self alloc] init];
    });
    
    return proxy;
}

- (instancetype)init {
    self = [super init];
    
    _queue = dispatch_queue_create("org.reactivecocoa.ReactiveObjC.RLKVOProxy", DISPATCH_QUEUE_SERIAL);
    _trampolines = [NSMapTable strongToWeakObjectsMapTable];
    
    return self;
}

- (void)addObserver:(__weak NSObject *)observer forContext:(void *)context {
    NSValue *valueContext = [NSValue valueWithPointer:context];
    
    dispatch_sync(self.queue, ^{
        [self.trampolines setObject:observer forKey:valueContext];
    });
}

- (void)removeObserver:(NSObject *)observer forContext:(void *)context {
    NSValue *valueContext = [NSValue valueWithPointer:context];
    
    dispatch_sync(self.queue, ^{
        [self.trampolines removeObjectForKey:valueContext];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSValue *valueContext = [NSValue valueWithPointer:context];
    __block NSObject *trueObserver;
    
    dispatch_sync(self.queue, ^{
        trueObserver = [self.trampolines objectForKey:valueContext];
    });
    
    if (trueObserver != nil) {
        [trueObserver observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@interface RLKVOTrampoline : RLLiberation
@end

@interface RLKVOTrampoline ()

@property (nonatomic, readonly, copy) NSString *keyPath;
@property (nonatomic, readonly, copy) RLKVOBlock block;

@property (nonatomic, readonly, unsafe_unretained) NSObject *unsafeTarget;

@property (nonatomic, readonly, weak) NSObject *weakTarget;
@property (nonatomic, readonly, weak) NSObject *observer;

@end

@implementation RLKVOTrampoline

#pragma mark Lifecycle

- (instancetype)initWithTarget:(__weak NSObject *)target observer:(__weak NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(RLKVOBlock)block {
    NSCParameterAssert(keyPath != nil);
    NSCParameterAssert(block != nil);
    
    NSObject *strongTarget = target;
    if (strongTarget == nil) return nil;
    
    self = [super init];
    
    _keyPath = [keyPath copy];
    
    _block = [block copy];
    _weakTarget = target;
    _unsafeTarget = strongTarget;
    _observer = observer;
    
    [RLKVOProxy.sharedProxy addObserver:self forContext:(__bridge void *)self];
    [strongTarget addObserver:RLKVOProxy.sharedProxy forKeyPath:self.keyPath options:options context:(__bridge void *)self];
    
    [strongTarget.rl_deallocLiberation addLiberation:self];
    [self.observer.rl_deallocLiberation addLiberation:self];
    
    return self;
}

- (void)dealloc {
    [self liberate];
}

#pragma mark Observation

- (void)liberate {
    NSObject *target;
    NSObject *observer;
    
    @synchronized (self) {
        target = self.unsafeTarget;
        observer = self.observer;
        
        _block = nil;
        _unsafeTarget = nil;
        _observer = nil;
    }
    
    [target.rl_deallocLiberation removeLiberation:self];
    [observer.rl_deallocLiberation removeLiberation:self];
    
    [target removeObserver:RLKVOProxy.sharedProxy forKeyPath:self.keyPath context:(__bridge void *)self];
    [RLKVOProxy.sharedProxy removeObserver:self forContext:(__bridge void *)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != (__bridge void *)self) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    RLKVOBlock block;
    id observer;
    id target;
    
    @synchronized (self) {
        block = self.block;
        observer = self.observer;
        target = self.weakTarget;
    }
    if (block == nil || target == nil) return;
    block(target, observer, change);
}

@end

@implementation NSObject (RLKVOWrapper)

- (RLLiberation *)rl_observeKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(__weak NSObject *)observer block:(void (^)(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent))block; {
    NSCParameterAssert(block != nil);
    
    keyPath = [keyPath copy];
    NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."] ?: @[];
    NSCParameterAssert([keyPathComponents count]);
    
    BOOL keyPathHasOneComponent = (keyPathComponents.count == 1);
    NSString *keyPathHead = keyPathComponents[0];
    NSString *keyPathTail = [keyPath substringFromIndex:[keyPathHead length] + (!keyPathHasOneComponent)];
    
    NSObject *strongObserver = observer;
    RLCompoundLiberation *liberation = [RLCompoundLiberation compoundLiberation];
    RLSerialLiberation *firstComponentSerialLiberation = [RLSerialLiberation serialLiberationWithLiberation:[RLCompoundLiberation compoundLiberation]];
    RLCompoundLiberation * (^firstComponentLiberation)(void) = ^{
        return (RLCompoundLiberation *)firstComponentSerialLiberation.liberation;
    };
    [liberation addLiberation:firstComponentSerialLiberation];
    
    BOOL shouldAddDeallocObserver = NO;
    objc_property_t property = class_getProperty(object_getClass(self), keyPathHead.UTF8String);
    if (property != NULL) {
        rl_propertyAttributes *attributes = rl_copyPropertyAttributes(property);
        if (attributes != NULL) {
            @onExit {
                free(attributes);
            };
            BOOL isObject = attributes->objectClass != nil || strstr(attributes->type, @encode(id)) == attributes->type;
            BOOL isProtocol = attributes->objectClass == NSClassFromString(@"Protocol");
            BOOL isBlock = strcmp(attributes->type, @encode(void(^)(void))) == 0;
            BOOL isWeak = attributes->weak;
            
            shouldAddDeallocObserver = isObject && isWeak && !isBlock && !isProtocol;
        }
    }
    void (^addDeallocObserverToPropertyValue)(NSObject *) = ^(NSObject *value) {
        if (!shouldAddDeallocObserver) return;
        if (value == observer) return;
        
        NSDictionary *change = @{ NSKeyValueChangeKindKey: @(NSKeyValueChangeSetting), NSKeyValueChangeNewKey: NSNull.null};
        RLCompoundLiberation *valueLiberation = value.rl_deallocLiberation;
        RLLiberation *deallocLiberation = [RLLiberation liberationWithBlock:^{
            block(nil, change, YES, keyPathHasOneComponent);
        }];
        
        [valueLiberation addLiberation:deallocLiberation];
        [firstComponentLiberation() addLiberation:[RLLiberation liberationWithBlock:^{
            [valueLiberation removeLiberation:deallocLiberation];
        }]];
    };
    void (^addObserverToValue)(NSObject *) = ^(NSObject *value) {
        RLLiberation *observerLiberation = [value rl_observeKeyPath:keyPathTail options:(options & ~NSKeyValueObservingOptionInitial) observer:observer block:block];
        [firstComponentLiberation() addLiberation:observerLiberation];
    };
    NSKeyValueObservingOptions trampolineOptions = (options | NSKeyValueObservingOptionPrior) & ~NSKeyValueObservingOptionInitial;
    RLKVOTrampoline *trampoline = [[RLKVOTrampoline alloc] initWithTarget:self observer:strongObserver keyPath:keyPathHead options:trampolineOptions block:^(id trampolineTarget, id trampolineObserver, NSDictionary *change) {
        if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
            [firstComponentLiberation() liberate];
            if ((options & NSKeyValueObservingOptionPrior) != 0) {
                block([trampolineTarget valueForKeyPath:keyPath], change, NO, keyPathHasOneComponent);
            }
            return;
        }
        NSObject *value = [trampolineTarget valueForKey:keyPathHead];
        if (value == nil) {
            block(nil, change, NO, keyPathHasOneComponent);
            return;
        }
        RLLiberation *oldFirstComponentLiberation = [firstComponentSerialLiberation swapInLiberation:[RLCompoundLiberation compoundLiberation]];
        [oldFirstComponentLiberation liberate];
        
        addDeallocObserverToPropertyValue(value);
        
        if (keyPathHasOneComponent) {
            block(value, change, NO, keyPathHasOneComponent);
            return;
        }
        addObserverToValue(value);
        block([value valueForKeyPath:keyPathTail], change, NO, keyPathHasOneComponent);
    }];
    
    [liberation addLiberation:trampoline];
    
    NSObject *value = [self valueForKey:keyPathHead];
    if (value != nil) {
        addDeallocObserverToPropertyValue(value);
        
        if (!keyPathHasOneComponent) {
            addObserverToValue(value);
        }
    }
    
    if ((options & NSKeyValueObservingOptionInitial) != 0) {
        id initialValue = [self valueForKeyPath:keyPath];
        NSDictionary *initialChange = @{ NSKeyValueChangeKindKey: @(NSKeyValueChangeSetting), NSKeyValueChangeNewKey: initialValue ?: NSNull.null };
        block(initialValue, initialChange, NO, keyPathHasOneComponent);
    }
    RLCompoundLiberation *observerLiberation = strongObserver.rl_deallocLiberation;
    RLCompoundLiberation *selfLiberation = self.rl_deallocLiberation;
    
    [observerLiberation addLiberation:liberation];
    [selfLiberation addLiberation:liberation];
    
    return [RLLiberation liberationWithBlock:^{
        [liberation liberate];
        [observerLiberation removeLiberation:liberation];
        [selfLiberation removeLiberation:liberation];
    }];
}

- (RLStream *)rl_valuesForKeyPath:(NSString *)keyPath observer:(__weak NSObject *)observer {
    return [[[self rl_valuesAndChangesForKeyPath:keyPath options:NSKeyValueObservingOptionInitial observer:observer] map:^(NSArray *values) {
        return [values firstObject];
    }] setNameWithFormat:@"RLObserve(%@, %@)", self, keyPath];
}

- (RLStream *)rl_valuesAndChangesForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(__weak NSObject *)weakObserver {
    NSObject *strongObserver = weakObserver;
    keyPath = [keyPath copy];
    
    NSRecursiveLock *objectLock = [[NSRecursiveLock alloc] init];
    objectLock.name = @"org.reactivecocoa.ReactiveObjC.NSObjectRLPropertySubscribing";
    
    __weak NSObject *weakSelf = self;
    RLStream *deallocStream = [[RLStream zip:@[ self.rl_willDeallocStream, strongObserver.rl_willDeallocStream ?: [RLStream never] ]] doComplet:^{
        [objectLock lock];
        @onExit {
            [objectLock unlock];
        };
    }];
    return [[[RLStream create:^RLLiberation * (id<RLObserver> observer) {
        [objectLock lock];
        @onExit {
            [objectLock unlock];
        };
        __strong NSObject *observerTarget __attribute__((objc_precise_lifetime)) = weakObserver;
        __strong NSObject *self __attribute__((objc_precise_lifetime)) = weakSelf;
        if (!self) {
            [observer complete];
            return nil;
        }
        return [self rl_observeKeyPath:keyPath options:options observer:observerTarget block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
            [observer output:@[value, change]];
        }];
    }] takeUntil:deallocStream] setNameWithFormat:@"%@ -rl_valueAndChangesForKeyPath: %@ options: %lu observer: %@", self, keyPath, (unsigned long)options, strongObserver];
}

@end
