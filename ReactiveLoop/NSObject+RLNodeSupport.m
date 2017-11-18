//
//  NSObject+RLNodeSupport.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+RLNodeSupport.h"
#import "NSObject+RLSelectorStream.h"

#import "RLStream+RLNodeSupportPrivate.h"
#import "RLNode.h"

@implementation NSObject (RLNodeSupport)

- (NSMutableArray<RLNode *> *)rl_associated_nodes{
    NSMutableArray<RLNode *> *nodes = objc_getAssociatedObject(self, @selector(rl_associated_nodes));
    if (!nodes) {
        nodes = [[NSMutableArray<RLNode *> alloc] init];
        objc_setAssociatedObject(self, @selector(rl_associated_nodes), nodes, OBJC_ASSOCIATION_RETAIN);
    }
    return nodes;
}

- (void)setRl_name:(NSString *)rl_name{
    objc_setAssociatedObject(self, @selector(rl_name), rl_name, OBJC_ASSOCIATION_COPY);
}

- (NSString *)rl_name{
    return objc_getAssociatedObject(self, @selector(rl_name));
}

- (NSArray<RLNode *> *)rl_nodes{
    return [[self rl_associated_nodes] copy];
}

- (RLNode *)rl_nodeWithStream:(RLStream *)stream;{
    RLNode *node = [stream node];
    
    [[self rl_associated_nodes] addObject:node];
    
    return node;
}

- (RLNode *)rl_nodeWithSelector:(SEL)selector;{
    if (![self respondsToSelector:selector]) return nil;
    RLStream *stream = [self rl_streamForSelector:selector];
    RLNode *node = [stream node];
    
    [[self rl_associated_nodes] addObject:node];
    
    return node;
}

- (RLNode *)rl_nodeWithRule:(RLRule *)rule stream:(RLStream *)stream;{
    RLNode *node = [stream nodeWithRule:rule];
    
    [[self rl_associated_nodes] addObject:node];
    return node;
}

- (RLNode *)rl_nodeWithRules:(NSArray<RLRule *> *)rules stream:(RLStream *)stream;{
    RLNode *node = [stream nodeWithRules:rules];
    
    [[self rl_associated_nodes] addObject:node];
    
    return node;
}

- (RLNode *)rl_nodeWithRule:(RLRule *)rule forSelector:(SEL)selector;{
    if (![self respondsToSelector:selector]) return nil;
    
    RLStream *stream = [self rl_streamForSelector:selector];
    return [self rl_nodeWithRule:rule stream:stream];
}

- (RLNode *)rl_nodeWithRules:(NSArray<RLRule *> *)rules forSelector:(SEL)selector;{
    if (![self respondsToSelector:selector]) return nil;
    
    RLStream *stream = [self rl_streamForSelector:selector];
    return [self rl_nodeWithRules:rules stream:stream];
}

@end
