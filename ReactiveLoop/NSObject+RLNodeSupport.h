//
//  NSObject+RLNodeSupport.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLRule, RLNode, RLStream;
@interface NSObject (RLNodeSupport)

@property (nonatomic, copy, readonly) NSArray<RLNode *> *rl_nodes;

@property (nonatomic, copy) NSString *rl_name;

- (RLNode *)rl_nodeWithStream:(RLStream *)stream;
- (RLNode *)rl_nodeWithSelector:(SEL)selector;

- (RLNode *)rl_nodeWithRule:(RLRule *)rule stream:(RLStream *)stream;
- (RLNode *)rl_nodeWithRules:(NSArray<RLRule *> *)rules stream:(RLStream *)stream;

- (RLNode *)rl_nodeWithRule:(RLRule *)rule forSelector:(SEL)selector;
- (RLNode *)rl_nodeWithRules:(NSArray<RLRule *> *)rules forSelector:(SEL)selector;

@end
