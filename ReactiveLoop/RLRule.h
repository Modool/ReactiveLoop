//
//  RLRule.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLRule : RLStream

+ (instancetype)rule;
+ (instancetype)ruleWithBlock:(id _Nullable (^)(_Nullable id value))block;

- (void)ignoreRule:(__kindof RLRule *)rule;

@end

@interface RLRule ()

@property (strong, readonly, nullable) id value;

@end

@interface RLRule (RLRuleOperation)

+ (__kindof RLRule *)combineRules:(NSArray<__kindof RLRule *> *)rules;

+ (__kindof RLRule *)mergeRules:(NSArray<__kindof RLRule *> *)rules;

- (__kindof RLRule *)combine:(__kindof RLRule *)rule;

- (__kindof RLRule *)merge:(__kindof RLRule *)rule;

- (__kindof RLRule *)and;

- (__kindof RLRule *)or;

- (__kindof RLRule *)not;

@end

NS_ASSUME_NONNULL_END
