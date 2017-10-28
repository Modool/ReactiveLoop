//
//  NSObject+RLDeallocating.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/message.h>
#import <objc/runtime.h>

#import "NSObject+RLDeallocating.h"

#import "RLEvent.h"
#import "RLLiberation.h"

static const void *RLObjectCompoundLiberation = &RLObjectCompoundLiberation;

static NSMutableSet *rl_swizzledDeallocClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *rl_swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        rl_swizzledClasses = [[NSMutableSet alloc] init];
    });
    
    return rl_swizzledClasses;
}

static void rl_swizzleDeallocIfNeeded(Class classToSwizzle) {
    @synchronized (rl_swizzledDeallocClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([rl_swizzledDeallocClasses() containsObject:className]) return;
        
        SEL deallocSelector = sel_registerName("dealloc");
        
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        
        id newDealloc = ^(__unsafe_unretained id self) {
            RLCompoundLiberation *compoundLiberation = objc_getAssociatedObject(self, RLObjectCompoundLiberation);
            [compoundLiberation liberate];
            
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };
                
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        
        [rl_swizzledDeallocClasses() addObject:className];
    }
}

@implementation NSObject (RLDeallocating)

- (RLStream *)rl_willDeallocStream {
    RLStream *stream = objc_getAssociatedObject(self, _cmd);
    if (stream != nil) return stream;
    
    RLReplayEvent *event = [RLReplayEvent event];
    
    [self.rl_deallocLiberation addLiberation:[RLLiberation liberationWithBlock:^{
        [event complete];
    }]];
    
    objc_setAssociatedObject(self, _cmd, event, OBJC_ASSOCIATION_RETAIN);
    
    return event;
}

- (RLCompoundLiberation *)rl_deallocLiberation {
    @synchronized (self) {
        RLCompoundLiberation *compoundLiberation = objc_getAssociatedObject(self, RLObjectCompoundLiberation);
        if (compoundLiberation != nil) return compoundLiberation;
        
        rl_swizzleDeallocIfNeeded(self.class);
        
        compoundLiberation = [RLCompoundLiberation compoundLiberation];
        objc_setAssociatedObject(self, RLObjectCompoundLiberation, compoundLiberation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return compoundLiberation;
    }
}

@end
