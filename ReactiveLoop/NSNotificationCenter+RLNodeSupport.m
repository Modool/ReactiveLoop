//
//  NSNotificationCenter+RLNodeSupport.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "NSNotificationCenter+RLNodeSupport.h"
#import "NSObject+RLNodeSupport.h"
#import "NSObject+RLKVOWrapper.h"
#import "RLEXTScope.h"
#import "RLStream.h"
#import "RLObserver.h"
#import "RLLiberation.h"

@implementation NSNotificationCenter (RLNodeSupport)

- (RLNode *)rl_nodeForNotificationName:(NSString *)notificationName{
    return [self rl_nodeForNotificationName:notificationName object:nil];
}

- (RLNode *)rl_nodeForNotificationName:(NSString *)notificationName object:(id)object;{
    NSParameterAssert(notificationName != nil);
    
    NSMutableDictionary<NSString *, RLNode *> *nodes = objc_getAssociatedObject(self, @selector(rl_nodeForNotificationName:object:));
    if (!nodes) {
        nodes = [[NSMutableDictionary<NSString *, RLNode *> alloc] init];
        objc_setAssociatedObject(self, @selector(rl_nodeForNotificationName:object:), nodes, OBJC_ASSOCIATION_RETAIN);
    }
    
    RLNode *node = nodes[notificationName];
    if (!node) {
        @unsafeify(object);
        RLStream *stream = [[RLStream create:^RLLiberation *(id<RLObserver> observer) {
            @strongify(object);
            id notificationObserver = [self addObserverForName:notificationName object:object queue:nil usingBlock:^(NSNotification *notification) {
                [observer output:notification];
            }];
            
            return [RLLiberation liberationWithBlock:^{
                [self removeObserver:notificationObserver];
            }];
        }] setNameWithFormat:@"-rac_addObserverForName: %@ object: <%@: %p>", notificationName, [object class], object];
        node = [super rl_nodeWithStream:stream];
        
        nodes[notificationName] = node;
    }
    return node;
}

@end
