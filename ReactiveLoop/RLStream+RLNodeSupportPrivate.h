//
//  RLStream+RLNodeSupportPrivate.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"

@class RLNode, RLRule;
@interface RLStream (RLNodeSupportPrivate)

- (RLNode *)node;
- (RLNode *)nodeWithRule:(RLRule *)rule;
- (RLNode *)nodeWithRules:(NSArray<RLRule *> *)rules;

@end
