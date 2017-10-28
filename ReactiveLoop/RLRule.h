//
//  RLRule.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLStream;
@interface RLRule : NSObject

@property (nonatomic, strong, readonly) RLStream *output;

+ (instancetype)ruleWithInput:(RLStream *)input;

@end

@interface RLRule (RLRuleOperation)

+ (__kindof RLRule *)return:(id)value;

+ (__kindof RLRule *)mergeRules:(NSArray<__kindof RLRule *> *)rules;

+ (__kindof RLRule *)combineRules:(NSArray<__kindof RLRule *> *)rules;

- (__kindof RLRule *)combine:(__kindof RLRule *)rule;

+ (__kindof RLRule *)and:(NSArray<__kindof RLRule *> *)rules;
- (__kindof RLRule *)and;

+ (__kindof RLRule *)or:(NSArray<__kindof RLRule *> *)rules;
- (__kindof RLRule *)or;

- (__kindof RLRule *)not;

@end

NS_ASSUME_NONNULL_END
