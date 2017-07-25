//
//  RLRule.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLRule.h"

#import "RLAndRule.h"
#import "RLOrRule.h"
#import "RLCombinedRule.h"
#import "RLMergedRule.h"

@implementation RLRule

@end

@implementation RLRule (RLRuleOperation)

+ (__kindof RLRule *)combineRules:(NSArray<__kindof RLRule *> *)rules;{
    return [RLCombinedRule ruleWithRules:rules];
}

+ (__kindof RLRule *)mergeRules:(NSArray<__kindof RLRule *> *)rules;{
    return [RLMergedRule ruleWithRules:rules];
}

- (__kindof RLRule *)combine:(__kindof RLRule *)rule;{
    NSParameterAssert(rule);
    return [RLCombinedRule combineRules:@[self, rule]];
}

- (__kindof RLRule *)merge:(__kindof RLRule *)rule;{
    NSParameterAssert(rule);
    return [RLMergedRule ruleWithRules:@[self, rule]];
}

- (__kindof RLRule *)and;{
    NSParameterAssert([self isKindOfClass:[RLMultiRule class]]);
    
    return nil;
}

- (__kindof RLRule *)or;{
    
    return nil;
}

- (__kindof RLRule *)not;{
    
    return nil;
}

@end
