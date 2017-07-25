//
//  RLMultiRule.h
//  ReactiveLoopDemo
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLRule.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLMultiRule : RLRule

- (void)addRule:(__kindof RLRule *)rule;
- (void)removeRule:(__kindof RLRule *)rule;

+ (instancetype)ruleWithRules:(NSArray<__kindof RLRule *> *)rules;

@end

@interface RLMultiRule ()

@property (strong, readonly, nullable) NSArray<__kindof RLRule *> *rules;

@end

NS_ASSUME_NONNULL_END
