//
//  RLRule+Private.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/29.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLRule.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLMultiRule : RLRule

@property (nonatomic, copy, readonly, nullable) NSArray<__kindof RLRule *> *rules;

+ (instancetype)ruleWithRules:(NSArray<__kindof RLRule *> *)rules;

@end

@interface RLMergedRule : RLMultiRule

@end

@interface RLCombinedRule : RLMultiRule

@end

@interface RLAndRule : RLCombinedRule

@end

@interface RLOrRule : RLCombinedRule

@end

NS_ASSUME_NONNULL_END

