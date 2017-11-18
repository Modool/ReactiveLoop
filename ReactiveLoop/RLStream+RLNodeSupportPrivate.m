
//
//  RLStream+RLNodeSupportPrivate.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream+RLNodeSupportPrivate.h"

#import "RLNode.h"
#import "RLRule.h"

@implementation RLStream (RLNodeSupportPrivate)

- (RLNode *)node;{
    RLNode *node = [[RLNode node] setNameWithFormat:@"%@.%@", self.name, @"no rule"];
    
    [node attachStream:self];
    
    return node;
}

- (RLNode *)nodeWithRule:(RLRule *)rule;{
    NSParameterAssert(rule != nil);
    RLNode *node = [[RLNode nodeWithRule:rule] setNameWithFormat:@"%@.%@", self.name, rule.name];
    
    [node attachStream:self];
    
    return node;
}

- (RLNode *)nodeWithRules:(NSArray<RLRule *> *)rules;{
    NSParameterAssert(rules != nil && [rules count] != 0);
    
    NSString *name = [[rules valueForKey:@"name"] componentsJoinedByString:@"."];
    RLNode *node = [[RLNode nodeWithRules:rules] setNameWithFormat:@"%@.%@", self.name, name];
    
    [node attachStream:self];
    
    return node;
}

@end
