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

- (void)attachNode:(__kindof RLNode *)node;
- (void)detachNode:(__kindof RLNode *)node;

@end

@interface RLMultiNode ()

@property (strong, readonly) NSArray *nodes;

@end

NS_ASSUME_NONNULL_END
