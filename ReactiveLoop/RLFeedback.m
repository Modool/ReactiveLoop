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

