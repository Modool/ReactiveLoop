//
//  NSObject+RLSelectorStream.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/message.h>
#import <objc/runtime.h>

#import "NSObject+RLSelectorStream.h"
#import "NSObject+RLDeallocating.h"
#import "RLLiberation.h"
#import "RLEvent.h"

#import "RLEXTRuntimeExtensions.h"

@implementation NSInvocation (RLTypeParsing)

- (void)rl_setArgument:(id)object atIndex:(NSUInteger)index {
#define PULL_AND_SET(type, selector) \
do { \
type val = [object selector]; \
[self setArgument:&val atIndex:(NSInteger)index]; \
} while (0)
    
    const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
    // Skip const type qualifier.
    if (argType[0] == 'r') {
        argType++;
    }
    
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        [self setArgument:&object atIndex:(NSInteger)index];
    } else if (strcmp(argType, @encode(char)) == 0) {
        PULL_AND_SET(char, charValue);
    } else if (strcmp(argType, @encode(int)) == 0) {
        PULL_AND_SET(int, intValue);
    } else if (strcmp(argType, @encode(short)) == 0) {
        PULL_AND_SET(short, shortValue);
    } else if (strcmp(argType, @encode(long)) == 0) {
        PULL_AND_SET(long, longValue);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        PULL_AND_SET(long long, longLongValue);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        PULL_AND_SET(unsigned char, unsignedCharValue);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        PULL_AND_SET(unsigned int, unsignedIntValue);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        PULL_AND_SET(unsigned short, unsignedShortValue);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        PULL_AND_SET(unsigned long, unsignedLongValue);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        PULL_AND_SET(unsigned long long, unsignedLongLongValue);
    } else if (strcmp(argType, @encode(float)) == 0) {
        PULL_AND_SET(float, floatValue);
    } else if (strcmp(argType, @encode(double)) == 0) {
        PULL_AND_SET(double, doubleValue);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        PULL_AND_SET(BOOL, boolValue);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        const char *cString = [object UTF8String];
        [self setArgument:&cString atIndex:(NSInteger)index];
        [self retainArguments];
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        [self setArgument:&object atIndex:(NSInteger)index];
    } else {
        NSCParameterAssert([object isKindOfClass:NSValue.class]);
        
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment([object objCType], &valueSize, NULL);
        
#if DEBUG
        NSUInteger argSize = 0;
        NSGetSizeAndAlignment(argType, &argSize, NULL);
        NSCAssert(valueSize == argSize, @"Value size does not match argument size in -rl_setArgument: %@ atIndex: %lu", object, (unsigned long)index);
#endif
        unsigned char valueBytes[valueSize];
        [object getValue:valueBytes];
        
        [self setArgument:valueBytes atIndex:(NSInteger)index];
    }
#undef PULL_AND_SET
}

- (id)rl_argumentAtIndex:(NSUInteger)index {
#define WRAP_AND_RETURN(type) \
do { \
type val = 0; \
[self getArgument:&val atIndex:(NSInteger)index]; \
return @(val); \
} while (0)
    
    const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
    // Skip const type qualifier.
    if (argType[0] == 'r') {
        argType++;
    }
    
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing id returnObj;
        [self getArgument:&returnObj atIndex:(NSInteger)index];
        return returnObj;
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        __unsafe_unretained id block = nil;
        [self getArgument:&block atIndex:(NSInteger)index];
        return [block copy];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);
        
        unsigned char valueBytes[valueSize];
        [self getArgument:valueBytes atIndex:(NSInteger)index];
        
        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }
    
    return nil;
    
#undef WRAP_AND_RETURN
}

- (NSArray *)rl_arguments {
    NSUInteger numberOfArguments = self.methodSignature.numberOfArguments;
    NSMutableArray *argumentsArray = [NSMutableArray arrayWithCapacity:numberOfArguments - 2];
    for (NSUInteger index = 2; index < numberOfArguments; index++) {
        [argumentsArray addObject:[self rl_argumentAtIndex:index] ?: NSNull.null];
    }
    
    return argumentsArray;
}

- (void)setRac_arguments:(NSArray *)arguments {
    NSParameterAssert(arguments);
    NSCAssert(arguments.count == self.methodSignature.numberOfArguments - 2, @"Number of supplied arguments (%lu), does not match the number expected by the signature (%lu)", (unsigned long)arguments.count, (unsigned long)self.methodSignature.numberOfArguments - 2);
    
    NSUInteger index = 2;
    for (id arg in arguments) {
        [self rl_setArgument:(arg == NSNull.null ? nil : arg) atIndex:index];
        index++;
    }
}

- (id)rl_returnValue {
#define WRAP_AND_RETURN(type) \
do { \
type val = 0; \
[self getReturnValue:&val]; \
return @(val); \
} while (0)
    
    const char *returnType = self.methodSignature.methodReturnType;
    // Skip const type qualifier.
    if (returnType[0] == 'r') {
        returnType++;
    }
    
    if (strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
        __autoreleasing id returnObj;
        [self getReturnValue:&returnObj];
        return returnObj;
    } else if (strcmp(returnType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(returnType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(returnType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(returnType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(returnType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(returnType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(returnType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(returnType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(returnType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(returnType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(returnType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(returnType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(returnType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(returnType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(returnType, @encode(void)) == 0) {
        return nil;
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
        
        unsigned char valueBytes[valueSize];
        [self getReturnValue:valueBytes];
        
        return [NSValue valueWithBytes:valueBytes objCType:returnType];
    }
    
    return nil;
    
#undef WRAP_AND_RETURN
}

@end

NSString * const RLSelectorStreamErrorDomain = @"RLSelectorStreamErrorDomain";
const NSInteger RLSelectorStreamErrorMethodSwizzlingRace = 1;

static NSString * const RLStreamForSelectorAliasPrefix = @"rl_alias_";
static NSString * const RLSubclassSuffix = @"_RLSelectorStream";
static void *RLSubclassAssociationKey = &RLSubclassAssociationKey;

static NSMutableSet *rl_swizzledSelectorClasses() {
    static NSMutableSet *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

@implementation NSObject (RLSelectorStream)

static BOOL RLForwardInvocation(id self, NSInvocation *invocation) {
    SEL aliasSelector = RLAliasForSelector(invocation.selector);
    RLEvent *event = objc_getAssociatedObject(self, aliasSelector);
    
    Class class = object_getClass(invocation.target);
    BOOL respondsToAlias = [class instancesRespondToSelector:aliasSelector];
    if (respondsToAlias) {
        invocation.selector = aliasSelector;
        [invocation invoke];
    }
    
    if (event == nil) return respondsToAlias;
    
    [event output:invocation.rl_arguments];
    return YES;
}

static void RLSwizzleForwardInvocation(Class class) {
    SEL forwardInvocationSEL = @selector(forwardInvocation:);
    Method forwardInvocationMethod = class_getInstanceMethod(class, forwardInvocationSEL);
    
    // Preserve any existing implementation of -forwardInvocation:.
    void (*originalForwardInvocation)(id, SEL, NSInvocation *) = NULL;
    if (forwardInvocationMethod != NULL) {
        originalForwardInvocation = (__typeof__(originalForwardInvocation))method_getImplementation(forwardInvocationMethod);
    }

    id newForwardInvocation = ^(id self, NSInvocation *invocation) {
        BOOL matched = RLForwardInvocation(self, invocation);
        if (matched) return;
        
        if (originalForwardInvocation == NULL) {
            [self doesNotRecognizeSelector:invocation.selector];
        } else {
            originalForwardInvocation(self, forwardInvocationSEL, invocation);
        }
    };
    
    class_replaceMethod(class, forwardInvocationSEL, imp_implementationWithBlock(newForwardInvocation), "v@:@");
}

static void RLSwizzleRespondsToSelector(Class class) {
    SEL respondsToSelectorSEL = @selector(respondsToSelector:);
    
    // Preserve existing implementation of -respondsToSelector:.
    Method respondsToSelectorMethod = class_getInstanceMethod(class, respondsToSelectorSEL);
    BOOL (*originalRespondsToSelector)(id, SEL, SEL) = (__typeof__(originalRespondsToSelector))method_getImplementation(respondsToSelectorMethod);
    
    // Set up a new version of -respondsToSelector: that returns YES for methods
    // added by -rl_streamForSelector:.
    //
    // If the selector has a method defined on the receiver's actual class, and
    // if that method's implementation is _objc_msgForward, then returns whether
    // the instance has a stream for the selector.
    // Otherwise, call the original -respondsToSelector:.
    id newRespondsToSelector = ^ BOOL (id self, SEL selector) {
        Method method = rl_getImmediateInstanceMethod(class, selector);
        
        if (method != NULL && method_getImplementation(method) == _objc_msgForward) {
            SEL aliasSelector = RLAliasForSelector(selector);
            if (objc_getAssociatedObject(self, aliasSelector) != nil) return YES;
        }
        
        return originalRespondsToSelector(self, respondsToSelectorSEL, selector);
    };
    
    class_replaceMethod(class, respondsToSelectorSEL, imp_implementationWithBlock(newRespondsToSelector), method_getTypeEncoding(respondsToSelectorMethod));
}

static void RLSwizzleGetClass(Class class, Class statedClass) {
    SEL selector = @selector(class);
    Method method = class_getInstanceMethod(class, selector);
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, selector, newIMP, method_getTypeEncoding(method));
}

static void RLSwizzleMethodSignatureForSelector(Class class) {
    IMP newIMP = imp_implementationWithBlock(^(id self, SEL selector) {
        // Don't send the -class message to the receiver because we've changed
        // that to return the original class.
        Class actualClass = object_getClass(self);
        Method method = class_getInstanceMethod(actualClass, selector);
        if (method == NULL) {
            // Messages that the original class dynamically implements fall
            // here.
            //
            // Call the original class' -methodSignatureForSelector:.
            struct objc_super target = {
                .super_class = class_getSuperclass(class),
                .receiver = self,
            };
            NSMethodSignature * (*messageSend)(struct objc_super *, SEL, SEL) = (__typeof__(messageSend))objc_msgSendSuper;
            return messageSend(&target, @selector(methodSignatureForSelector:), selector);
        }
        
        char const *encoding = method_getTypeEncoding(method);
        return [NSMethodSignature signatureWithObjCTypes:encoding];
    });
    
    SEL selector = @selector(methodSignatureForSelector:);
    Method methodSignatureForSelectorMethod = class_getInstanceMethod(class, selector);
    class_replaceMethod(class, selector, newIMP, method_getTypeEncoding(methodSignatureForSelectorMethod));
}

// It's hard to tell which struct return types use _objc_msgForward, and
// which use _objc_msgForward_stret instead, so just exclude all struct, array,
// union, complex and vector return types.
static void RLCheckTypeEncoding(const char *typeEncoding) {
#if !NS_BLOCK_ASSERTIONS
    // Some types, including vector types, are not encoded. In these cases the
    // signature starts with the size of the argument frame.
    NSCAssert(*typeEncoding < '1' || *typeEncoding > '9', @"unknown method return type not supported in type encoding: %s", typeEncoding);
    NSCAssert(strstr(typeEncoding, "(") != typeEncoding, @"union method return type not supported");
    NSCAssert(strstr(typeEncoding, "{") != typeEncoding, @"struct method return type not supported");
    NSCAssert(strstr(typeEncoding, "[") != typeEncoding, @"array method return type not supported");
    NSCAssert(strstr(typeEncoding, @encode(_Complex float)) != typeEncoding, @"complex float method return type not supported");
    NSCAssert(strstr(typeEncoding, @encode(_Complex double)) != typeEncoding, @"complex double method return type not supported");
    NSCAssert(strstr(typeEncoding, @encode(_Complex long double)) != typeEncoding, @"complex long double method return type not supported");
    
#endif // !NS_BLOCK_ASSERTIONS
}

static RLStream *NSObjectRLStreamForSelector(NSObject *self, SEL selector, Protocol *protocol) {
    SEL aliasSelector = RLAliasForSelector(selector);
    
    @synchronized (self) {
        RLEvent *event = objc_getAssociatedObject(self, aliasSelector);
        if (event != nil) return event;
        
        Class class = RLSwizzleClass(self);
        NSCAssert(class != nil, @"Could not swizzle class of %@", self);
        
        event = [[RLEvent event] setNameWithFormat:@"%@ -rl_streamForSelector: %s", self, sel_getName(selector)];
        objc_setAssociatedObject(self, aliasSelector, event, OBJC_ASSOCIATION_RETAIN);
        
        [self.rl_deallocLiberation addLiberation:[RLLiberation liberationWithBlock:^{
            [event complete];
        }]];
        
        Method targetMethod = class_getInstanceMethod(class, selector);
        if (targetMethod == NULL) {
            const char *typeEncoding;
            if (protocol == NULL) {
                typeEncoding = RLSignatureForUndefinedSelector(selector);
            } else {
                // Look for the selector as an optional instance method.
                struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
                
                if (methodDescription.name == NULL) {
                    // Then fall back to looking for a required instance
                    // method.
                    methodDescription = protocol_getMethodDescription(protocol, selector, YES, YES);
                    NSCAssert(methodDescription.name != NULL, @"Selector %@ does not exist in <%s>", NSStringFromSelector(selector), protocol_getName(protocol));
                }
                
                typeEncoding = methodDescription.types;
            }
            
            RLCheckTypeEncoding(typeEncoding);
            
            // Define the selector to call -forwardInvocation:.
            if (!class_addMethod(class, selector, _objc_msgForward, typeEncoding)) {
                return [RLStream empty];
            }
        } else if (method_getImplementation(targetMethod) != _objc_msgForward) {
            // Make a method alias for the existing method implementation.
            const char *typeEncoding = method_getTypeEncoding(targetMethod);
            
            RLCheckTypeEncoding(typeEncoding);
            
            BOOL addedAlias __attribute__((unused)) = class_addMethod(class, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), class);
            
            // Redefine the selector to call -forwardInvocation:.
            class_replaceMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
        }
        
        return event;
    }
}

static SEL RLAliasForSelector(SEL originalSelector) {
    NSString *selectorName = NSStringFromSelector(originalSelector);
    return NSSelectorFromString([RLStreamForSelectorAliasPrefix stringByAppendingString:selectorName]);
}

static const char *RLSignatureForUndefinedSelector(SEL selector) {
    const char *name = sel_getName(selector);
    NSMutableString *signature = [NSMutableString stringWithString:@"v@:"];
    
    while ((name = strchr(name, ':')) != NULL) {
        [signature appendString:@"@"];
        name++;
    }
    
    return signature.UTF8String;
}

static Class RLSwizzleClass(NSObject *self) {
    Class statedClass = self.class;
    Class baseClass = object_getClass(self);
    
    // The "known dynamic subclass" is the subclass generated by RL.
    // It's stored as an associated object on every instance that's already
    // been swizzled, so that even if something else swizzles the class of
    // this instance, we can still access the RL generated subclass.
    Class knownDynamicSubclass = objc_getAssociatedObject(self, RLSubclassAssociationKey);
    if (knownDynamicSubclass != Nil) return knownDynamicSubclass;
    
    NSString *className = NSStringFromClass(baseClass);
    
    if (statedClass != baseClass) {
        // If the class is already lying about what it is, it's probably a KVO
        // dynamic subclass or something else that we shouldn't subclass
        // ourselves.
        //
        // Just swizzle -forwardInvocation: in-place. Since the object's class
        // was almost certainly dynamically changed, we shouldn't see another of
        // these classes in the hierarchy.
        //
        // Additionally, swizzle -respondsToSelector: because the default
        // implementation may be ignorant of methods added to this class.
        @synchronized (rl_swizzledSelectorClasses()) {
            if (![rl_swizzledSelectorClasses() containsObject:className]) {
                RLSwizzleForwardInvocation(baseClass);
                RLSwizzleRespondsToSelector(baseClass);
                RLSwizzleGetClass(baseClass, statedClass);
                RLSwizzleGetClass(object_getClass(baseClass), statedClass);
                RLSwizzleMethodSignatureForSelector(baseClass);
                [rl_swizzledSelectorClasses() addObject:className];
            }
        }
        
        return baseClass;
    }
    
    const char *subclassName = [className stringByAppendingString:RLSubclassSuffix].UTF8String;
    Class subclass = objc_getClass(subclassName);
    
    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseClass, subclassName, 0);
        if (subclass == nil) return nil;
        
        RLSwizzleForwardInvocation(subclass);
        RLSwizzleRespondsToSelector(subclass);
        
        RLSwizzleGetClass(subclass, statedClass);
        RLSwizzleGetClass(object_getClass(subclass), statedClass);
        
        RLSwizzleMethodSignatureForSelector(subclass);
        
        objc_registerClassPair(subclass);
    }
    
    object_setClass(self, subclass);
    objc_setAssociatedObject(self, RLSubclassAssociationKey, subclass, OBJC_ASSOCIATION_ASSIGN);
    return subclass;
}

- (RLStream *)rl_streamForSelector:(SEL)selector {
    NSCParameterAssert(selector != NULL);
    
    return NSObjectRLStreamForSelector(self, selector, NULL);
}

- (RLStream *)rl_streamForSelector:(SEL)selector fromProtocol:(Protocol *)protocol {
    NSCParameterAssert(selector != NULL);
    NSCParameterAssert(protocol != NULL);
    
    return NSObjectRLStreamForSelector(self, selector, protocol);
}

@end
