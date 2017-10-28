//
//  RLNode+Private.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/29.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLNode.h"

@interface RLNode (Private)

- (void)updateValue:(id)value;
- (void)performFeedbacksWithValue:(id)value;

- (void)addFeedback:(RLFeedback *)feedback;
- (void)removeFeedback:(RLFeedback *)feedback;

@end
