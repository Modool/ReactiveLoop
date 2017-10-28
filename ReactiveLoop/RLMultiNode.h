//
//  RLMultiNode.h
//  ReactiveLoopDemo
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLMultiNode : RLNode

@property (nonatomic, strong, readonly) NSArray *nodes;

@property (nonatomic, copy) BOOL (^shouldFeedback)(NSArray<RLNode *> *nodes);

- (void)attachNode:(__kindof RLNode *)node;
- (void)detachNode:(__kindof RLNode *)node;

@end

NS_ASSUME_NONNULL_END
