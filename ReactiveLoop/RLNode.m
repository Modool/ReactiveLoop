//
//  RLNode.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLNode.h"
#import "RLRule.h"
#import "RLEvent.h"
#import "RLFeedback+Private.h"
#import "NSObject+RLKVOWrapper.h"

#import "RLEXTScope.h"
#import "RLEXTKeyPathCoding.h"

@interface RLNode ()

@property (nonatomic, strong) id value;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong, readonly) RLReplayEvent *infoEvent;

@property (nonatomic, strong, readonly) NSMutableArray<RLRule *> *rules;

@property (nonatomic, strong, readonly) NSMutableArray<RLFeedback *> *feedbacks;

@end

@implementation RLNode

+ (instancetype)node;{
    return [[self alloc] init];
}

+ (instancetype)nodeWithRule:(RLRule *)rule;{
    NSParameterAssert(rule);
    return [[self alloc] initWithRule:rule];
}

+ (instancetype)nodeWithRules:(NSArray<RLRule *> *)rules;{
    rules = rules ?: @[];
    if ([rules count] == 0) {
        return [self node];
    } else if ([rules count] == 1) {
        return [[self alloc] initWithRule:[rules firstObject]];
    } else {
        return [[self alloc] initWithRule:[RLRule mergeRules:rules]];
    }
}

- (instancetype)initWithRule:(RLRule *)rule;{
    if (self = [self init]) {
        _rule = rule;
    }
    return self;
}

- (instancetype)init{
    if (self = [super init]) {
        _enabled = YES;
        _feedbacks = [[NSMutableArray<RLFeedback *> alloc] init];
        _infoEvent = [RLReplayEvent event];
        
        @weakify(self);
        [_infoEvent observeOutput:^(id  _Nonnull value) {
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

#pragma mark - private

- (void)addFeedback:(RLFeedback *)feedback;{
    [self removeFeedback:feedback];
    
    [[self feedbacks] addObject:feedback];
}

- (void)removeFeedback:(RLFeedback *)feedback{
    [[self feedbacks] removeObject:feedback];
}

- (void)performFeedbacksWithValue:(id)value{
    for (RLFeedback *feedback in [self feedbacks]) {
        feedback.block(feedback.value, value);
    }
}

- (void)updateValue:(id)value{
    self.value = value;
}

- (void)attachStream:(RLStream *)info;{
    RLStream *outputStream = info;
    if ([self rule]) {
        outputStream = [[[RLStream combineLatest:@[info, RLObserve(self, enabled), [[self rule] output]]] filter:^BOOL(NSArray *values) {
            id enabled = values[1];
            id allowed = values[2];
            if (enabled == [NSNull null] || allowed == [NSNull null] ) return NO;
            if (![allowed isKindOfClass:[NSNumber class]]) return NO;
            
            return [enabled boolValue] && [allowed boolValue];
        }] map:^id _Nullable(NSArray *values) {
            return [values firstObject];
        }];
    }
    [outputStream observe:[self infoEvent]];
}

#pragma mark - public

- (RLFeedback *)feedbackObserve:(void (^)(_Nullable id value, _Nullable id source))observeBlock;{
    return [self feedbackValue:nil observe:observeBlock];
}

- (RLFeedback *)feedbackValue:(nullable id)value observe:(void (^)(_Nullable id value, _Nullable id source))observeBlock;{
    RLFeedback *feedback = [RLFeedback feedbackValue:value node:self block:observeBlock];
    [self addFeedback:feedback];
    
    return feedback;
}

@end
