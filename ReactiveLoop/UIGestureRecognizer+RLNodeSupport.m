//
//  UIGestureRecognizer+RLNodeSupport.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "UIGestureRecognizer+RLNodeSupport.h"
#import "NSObject+RLNodeSupport.h"
#import "NSObject+RLKVOWrapper.h"
#import "RLEXTKeyPathCoding.h"
#import "RLStream.h"

@implementation UIGestureRecognizer (RLNodeSupport)

- (RLNode *)rl_stateNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_stateNode));
    if (node) {
        node = [super rl_nodeWithStream:RLObserve(self, state)];
        objc_setAssociatedObject(self, @selector(rl_stateNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_nodeForState:(UIGestureRecognizerState)state;{
    NSMutableDictionary<NSNumber *, RLNode *> *nodes = objc_getAssociatedObject(self, @selector(rl_nodeForState:));
    if (!nodes) {
        nodes = [[NSMutableDictionary<NSNumber *, RLNode *> alloc] init];
        objc_setAssociatedObject(self, @selector(rl_nodeForState:), nodes, OBJC_ASSOCIATION_RETAIN);
    }
    
    RLNode *node = nodes[@(state)];
    if (!node) {
        node = [super rl_nodeWithStream:[RLObserve(self, state) filter:^BOOL (NSNumber *currentState){
            return [currentState integerValue] == state;
        }]];
        nodes[@(state)] = node;
    }
    return node;
}

@end
