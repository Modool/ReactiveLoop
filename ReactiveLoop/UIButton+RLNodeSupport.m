//
//  UIButton+RLNodeSupport.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/29.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "UIButton+RLNodeSupport.h"
#import "UIControl+RLStreamSupport.h"
#import "NSObject+RLNodeSupport.h"

#import "RLNode.h"

@implementation UIButton (RLNodeSupport)

- (RLNode *)rl_node{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_node));
    if (node) {
        node = [[super rl_nodeWithStream:[self rl_signalForControlEvents:UIControlEventTouchUpInside]] setNameWithFormat:@"%@.%d", NSStringFromClass([self class]), (NSUInteger)self];
        objc_setAssociatedObject(self, @selector(rl_node), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

@end
