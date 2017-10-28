//
//  RLNode.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLNode.h"
#import "RLNode+Private.h"
#import "RLRule.h"
#import "RLEvent.h"

#import "RLEXTScope.h"

@interface RLFeedback ()

@property (nonatomic, copy, readonly) void (^block)(id value);

@property (nonatomic, weak, readonly) RLNode *node;

@end

@implementation RLFeedback

+ (instancetype)feedbackWithBlock:(void (^)(id value))block node:(RLNode *)node;{
    return [[self alloc] initWithBlock:block node:node];
}

- (instancetype)initWithBlock:(void (^)(id value))block node:(RLNode *)node;{
    if (self = [super init]) {
        _block = [block copy];
        _node = node;
    }
    return self;
}

- (void)cancel{
    [[self node] removeFeedback:self];
}

@end

@interface RLNode ()

@property (nonatomic, strong) id value;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong, readonly) RLReplayEvent *infoEvent;

@property (nonatomic, strong, readonly) RLRule *rule;

@property (nonatomic, strong, readonly) NSMutableArray<RLRule *> *rules;

@property (nonatomic, strong, readonly) NSMutableArray<RLFeedback *> *feedbacks;

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
        _enabled = YES;
        _rules = [NSMutableArray arrayWithArray:rules ?: @[]];
        _feedbacks = [NSMutableArray new];
        _infoEvent = [RLReplayEvent event];
        _rule = [RLRule mergeRules:rules];
        
        @weakify(self);
        [[[_rule output] filter:^BOOL(id  _Nullable value) {
            @strongify(self);
            return [self enabled];
        }] observeOutput:^(id  _Nonnull value) {
            @strongify(self);
            [self updateValue:value];
            [self performFeedbacksWithValue:value];
        }];
    }
    return self;
}

- (instancetype)setNameWithFormat:(NSString *)format, ... {
    NSCParameterAssert(format != nil);
    
    va_list args;
    va_start(args, format);
    
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    self.name = str;
    return self;
}

#pragma mark - accessor

- (RLStream *)relatedInfoStream{
    return [self infoEvent];
}

#pragma mark - feedback

- (void)addFeedback:(RLFeedback *)feedback;{
    [self removeFeedback:feedback];
    
    [[self feedbacks] addObject:feedback];
}

- (void)removeFeedback:(RLFeedback *)feedback{
    [[self feedbacks] removeObject:feedback];
}

- (RLFeedback *)feedbackObserve:(void (^)(id value))block;{
    RLFeedback *feedback = [RLFeedback feedbackWithBlock:block node:self];
    [self addFeedback:feedback];
    
    return feedback;
}

- (void)performFeedbacksWithValue:(id)value{
    for (RLFeedback *feedback in [self feedbacks]) {
        feedback.block(value);
    }
}

- (void)updateValue:(id)value{
    self.value = value;
}

- (void)attachInfo:(RLStream *)info;{
    [info observe:[self infoEvent]];
}


@end
