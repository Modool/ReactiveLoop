//
//  RLFeedback.m
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLFeedback.h"
#import "RLFeedback+Private.h"
#import "RLNode+Private.h"

#import "RLLiberation.h"

@interface RLFeedback ()

@property (nonatomic, weak, readonly) RLNode *node;

@property (nonatomic, strong, readonly) RLLiberation *liberation;

@end

@implementation RLFeedback

+ (instancetype)feedbackValue:(nullable id)value node:(RLNode *)node liberation:(RLLiberation *)liberation{
    return [[self alloc] initWithValue:value node:node liberation:liberation];
}

- (instancetype)initWithValue:(nullable id)value node:(RLNode *)node liberation:(RLLiberation *)liberation{
    if (self = [super init]) {
        _value = value;
        _node = node;
        _liberation = liberation;
    }
    return self;
}

- (void)cancel{
    [[self node] removeFeedback:self];
    [[self liberation] liberate];
}

- (void)dealloc{
    [self cancel];
}

@end

