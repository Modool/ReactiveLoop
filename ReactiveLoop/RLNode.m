//
//  RLNode.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLNode.h"

@interface RLNode ()

@property (nonatomic, assign) BOOL enabled;

@property (nonatomic, strong) id value;

@end

@implementation RLNode

+ (instancetype)node;{
    return [self nodeWithRules:@[]];
}

+ (instancetype)nodeWithRule:(RLRule *)rule;{
    NSParameterAssert(rule);
    return [self nodeWithRules:@[rule]];
}

+ (instancetype)nodeWithRules:(NSArray<RLRule *> *)rules;{
    return [[self alloc] initWithRules:rules];
}

- (instancetype)initWithRules:(NSArray<RLRule *> *)rules;{
    if (self = [super init]) {
        
    }
    return self;
}

@end
