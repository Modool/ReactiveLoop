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

@interface RLFeedback ()

@property (nonatomic, weak, readonly) RLNode *node;

@property (nonatomic, copy, readonly) void (^block)(_Nullable id value, _Nullable id source);

@end

@implementation RLFeedback

+ (instancetype)feedbackValue:(nullable id)value node:(RLNode *)node block:(void (^)(_Nullable id value, _Nullable id source))block;{
    return [[self alloc] initWithValue:value node:node block:block];
}

- (instancetype)initWithValue:(nullable id)value node:(RLNode *)node block:(void (^)(_Nullable id value, _Nullable id source))block;{
    if (self = [super init]) {
        _value = value;
        _node = node;
        _block = [block copy];
    }
    return self;
}

- (void)cancel{
    [[self node] removeFeedback:self];
}

@end

