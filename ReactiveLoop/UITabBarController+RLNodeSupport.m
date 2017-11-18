//
//  UITabBarController+RLNodeSupport.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "UITabBarController+RLNodeSupport.h"
#import "NSObject+RLNodeSupport.h"
#import "NSObject+RLKVOWrapper.h"
#import "RLEXTKeyPathCoding.h"
#import "RLStream.h"

@implementation UITabBarController (RLNodeSupport)

- (RLNode *)rl_selectedIndexNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_selectedIndexNode));
    if (node) {
        node = [super rl_nodeWithStream:RLObserve(self, selectedIndex)];
        objc_setAssociatedObject(self, @selector(rl_selectedIndexNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_nodeForSelectedIndex:(NSUInteger)index;{
    NSMutableDictionary<NSNumber *, RLNode *> *nodes = objc_getAssociatedObject(self, @selector(rl_nodeForSelectedIndex:));
    if (!nodes) {
        nodes = [[NSMutableDictionary<NSNumber *, RLNode *> alloc] init];
        objc_setAssociatedObject(self, @selector(rl_nodeForSelectedIndex:), nodes, OBJC_ASSOCIATION_RETAIN);
    }
    
    RLNode *node = nodes[@(index)];
    if (!node) {
        node = [super rl_nodeWithStream:[RLObserve(self, selectedIndex) filter:^BOOL (NSNumber *selectedIndex){
            return [selectedIndex integerValue] == index;
        }]];
        nodes[@(index)] = node;
    }
    return node;
}

@end
