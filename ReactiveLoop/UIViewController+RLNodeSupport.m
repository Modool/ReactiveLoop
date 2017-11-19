//
//  UIViewController+RLNodeSupport.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "UIViewController+RLNodeSupport.h"
#import "NSObject+RLSelectorStream.h"
#import "NSObject+RLNodeSupport.h"

@implementation UIViewController (RLNodeSupport)

- (RLNode *)rl_viewDidLoadNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_viewDidLoadNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(viewDidLoad)]];
        objc_setAssociatedObject(self, @selector(rl_viewDidLoadNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_viewWillAppearNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_viewWillAppearNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(viewWillAppear:)]];
        objc_setAssociatedObject(self, @selector(rl_viewWillAppearNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_viewDidAppearNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_viewDidAppearNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(viewDidAppear:)]];
        objc_setAssociatedObject(self, @selector(rl_viewDidAppearNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_viewWillDisappearNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_viewWillDisappearNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(viewWillDisappear:)]];
        objc_setAssociatedObject(self, @selector(rl_viewWillDisappearNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

- (RLNode *)rl_viewDidDisappearNode{
    RLNode *node = objc_getAssociatedObject(self, @selector(rl_viewDidDisappearNode));
    if (!node) {
        node = [super rl_nodeWithStream:[self rl_streamForSelector:@selector(viewDidDisappear:)]];
        objc_setAssociatedObject(self, @selector(rl_viewDidDisappearNode), node, OBJC_ASSOCIATION_RETAIN);
    }
    return node;
}

@end
