//
//  UIView+RLNodeSupport.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "UIView+RLNodeSupport.h"

#import "NSObject+RLNodeSupport.h"
#import "NSObject+RLSelectorStream.h"

#import "RLNode.h"

@implementation UIView (RLNodeSupport)

- (RLNode *)rl_moveInSuperviewNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_moveInSuperviewNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(didMoveToSuperview)]];
        objc_setAssociatedObject(self, @selector(rl_moveInSuperviewNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_moveOutSuperviewNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_moveOutSuperviewNode));
    if (!node) {
        node = [super rl_nodeWithStream:[[self rl_streamForSelector:@selector(willMoveToSuperview:)] filter:^BOOL(NSArray *arguments) {
            return [arguments lastObject] != nil;
        }]];
        objc_setAssociatedObject(self, @selector(rl_moveOutSuperviewNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_layoutSubviewsNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_layoutSubviewsNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(layoutSubviews)]];
        objc_setAssociatedObject(self, @selector(rl_layoutSubviewsNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

@end
