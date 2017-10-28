//
//  RLRule.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLRule.h"
#import "RLRule+Private.h"
#import "RLEvent.h"

@interface RLRule ()

@property (nonatomic, strong) RLStream *input;
@property (nonatomic, strong) RLStream *output;

@end

@implementation RLRule

+ (instancetype)ruleWithInput:(RLStream *)input;{
    return [[self alloc] initWithInput:input];
}

- (instancetype)initWithInput:(RLStream *)input;{
    if (self = [super init]) {
        self.input = input;
        
        RLReplayEvent *replayEvent = [RLReplayEvent event];
        [input observe:replayEvent];
        
        _output = replayEvent;
    }
    return self;
}

- (void)dealloc{
    self.input = nil;
}

@end

@implementation RLRule (RLRuleOperation)

+ (__kindof RLRule *)return:(id)value;{
    return [self ruleWithInput:[RLStream return:value]];
}

+ (__kindof RLRule *)mergeRules:(NSArray<__kindof RLRule *> *)rules;{
    return [RLMergedRule ruleWithRules:rules];
}

+ (__kindof RLRule *)combineRules:(NSArray<__kindof RLRule *> *)rules;{
    return [RLCombinedRule ruleWithRules:rules];
}

- (__kindof RLRule *)combine:(__kindof RLRule *)rule;{
    NSParameterAssert(rule);
    return [RLCombinedRule combineRules:@[self, rule]];
}

+ (__kindof RLRule *)and:(NSArray<__kindof RLRule *> *)rules{
    return [[self combineRules:rules] and];
}

- (__kindof RLRule *)and;{
    NSParameterAssert([self isKindOfClass:[RLMultiRule class]]);
    NSArray<RLRule *> *rules = [[(RLMultiRule *)self rules] copy];
    
    return [RLAndRule ruleWithRules:rules];
}

+ (__kindof RLRule *)or:(NSArray<__kindof RLRule *> *)rules;{
    return [[self combineRules:rules] or];
}

- (__kindof RLRule *)or;{
    NSParameterAssert([self isKindOfClass:[RLMultiRule class]]);
    NSArray<RLRule *> *rules = [[(RLMultiRule *)self rules] copy];
    return [RLOrRule ruleWithRules:rules];
}

- (__kindof RLRule *)not;{
    return [[self class] ruleWithInput:[[self output] map:^id(id value) {
        if (![value isKindOfClass:[NSNumber class]]) return nil;
        return @(![value boolValue]);
    }]];
}

@end

@interface RLMultiRule ()

@property (nonatomic, copy, nullable) NSArray<__kindof RLRule *> *rules;

@end

@implementation RLMultiRule

+ (instancetype)ruleWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSParameterAssert([self class] != [RLMultiRule class]);
    RLMultiRule *rule = [[self alloc] initWithRules:rules];
    rule.rules = rules;
    
    return rule;
}

- (instancetype)initWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSCAssert(NO, @"This method must be overridden by subclasses");
    return nil;
}

@end

@implementation RLMergedRule

- (instancetype)initWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSMutableArray *outpus = [NSMutableArray new];
    for (RLRule *rule in rules) {
        [outpus addObject:[rule output]];
    }
    return [super initWithInput:[RLStream merge:outpus]];
}

@end

@implementation RLCombinedRule

- (instancetype)initWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSMutableArray *outpus = [NSMutableArray new];
    for (RLRule *rule in rules) {
        [outpus addObject:[rule output]];
    }
    return [super initWithInput:[RLStream combineLatest:outpus]];
}

@end

@implementation RLAndRule

- (instancetype)initWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSMutableArray *outpus = [NSMutableArray new];
    for (RLRule *rule in rules) {
        [outpus addObject:[rule output]];
    }
    RLStream *input = [[RLStream combineLatest:outpus] map:^id(NSArray *values) {
        if (!values || ![values count]) return @NO;
    
        id first = values[0];
        BOOL reuslt = [first isKindOfClass:[NSNumber class]] ? [first boolValue] : NO;
    
        for (id value in values) {
            reuslt = (reuslt && ([value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO));
        }
        return @(reuslt);
    }];
    return [super initWithInput:input];
}

@end

@implementation RLOrRule

- (instancetype)initWithRules:(NSArray<__kindof RLRule *> *)rules;{
    NSMutableArray *outpus = [NSMutableArray new];
    for (RLRule *rule in rules) {
        [outpus addObject:[rule output]];
    }
    RLStream *input = [[RLStream combineLatest:outpus] map:^id(NSArray *values) {
        if (!values || ![values count]) return @NO;
        
        id first = values[0];
        BOOL reuslt = [first isKindOfClass:[NSNumber class]] ? [first boolValue] : NO;
        
        for (id value in values) {
            reuslt = (reuslt || ([value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO));
        }
        return @(reuslt);
    }];
    return [super initWithInput:input];
}

@end
