//
//  RLMultiNode.m
//  ReactiveLoopDemo
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLMultiNode.h"

@interface RLMultiNode ()

@property (nonatomic, strong) NSArray<RLNode *> *nodes;

@end

@implementation RLMultiNode

- (instancetype)init{
    if (self = [super init]) {
        self.nodes = @[];
    }
    return self;
}

- (void)attachNode:(__kindof RLNode *)node;{
    [self detachNode:node];
    
    self.nodes = [[self nodes]  arrayByAddingObject:node];
}

- (void)detachNode:(__kindof RLNode *)node;{
    NSMutableArray *nodes = [[self nodes] mutableCopy];
    [nodes removeObject:node];
    
    self.nodes = [nodes copy];
}

@end
