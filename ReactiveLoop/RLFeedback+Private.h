//
//  RLFeedback+Private.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLFeedback.h"

@class RLNode;
@interface RLFeedback (Private)

@property (nonatomic, copy, readonly) void (^block)(id value);

@property (nonatomic, weak, readonly) RLNode *node;

+ (instancetype)feedbackWithBlock:(void (^)(id value))block node:(RLNode *)node;
- (instancetype)initWithBlock:(void (^)(id value))block node:(RLNode *)node;

@end
