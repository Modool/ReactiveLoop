//
//  RLMultiNode.m
//  ReactiveLoopDemo
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLMultiNode.h"
#import "RLNode+Private.h"

#import "RLEXTScope.h"

@interface RLMultiNode (){
    NSMutableArray<RLNode *> *_mutableNodes;
}

@property (nonatomic, strong, readonly) NSMutableArray<RLFeedback *> *mutableSubNodeFeedbacks;

@end

@implementation RLMultiNode
@synthesize nodes = _mutableNodes;

- (instancetype)init{
    if (self = [super init]) {
        _mutableNodes = [[NSMutableArray<RLNode *> alloc] init];
        _mutableSubNodeFeedbacks = [[NSMutableArray<RLFeedback *> alloc] init];
    }
    return self;
}

- (void)feedbackIfNeeds{
    BOOL shouldFeedback = self.shouldFeedback ? self.shouldFeedback([[self nodes] copy]) : YES;
    if (!shouldFeedback) return;
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (RLNode *node in [[self nodes] copy]) {
        [values addObject:[[node relatedInfoStream] firstOrDefault:NSNull.null] ?: NSNull.null];
    }
    [self updateValue:values];
    [self performFeedbacksWithValue:values];
}

- (void)attachNode:(__kindof RLNode *)node;{
    [self detachNode:node];
    
    [_mutableNodes addObject:node];
    
    @weakify(self);
    RLFeedback *feedback = [node feedbackObserve:^(id  _Nonnull value) {
        @strongify(self);
        [self feedbackIfNeeds];
    }];
    if (feedback) {
        [_mutableSubNodeFeedbacks addObject:feedback];
    }
}

- (void)detachNode:(__kindof RLNode *)node;{
    [_mutableNodes removeObject:node];
}

@end
