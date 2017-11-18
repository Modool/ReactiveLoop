//
//  RLFeedback+Private.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLFeedback.h"

NS_ASSUME_NONNULL_BEGIN

@class RLNode;
@interface RLFeedback (Private)

@property (nonatomic, copy, readonly) void (^block)(_Nullable id value, _Nullable id source);

@property (nonatomic, weak, readonly) RLNode *node;

+ (instancetype)feedbackValue:(nullable id)value node:(RLNode *)node block:(void (^)(_Nullable id value, _Nullable id source))block;
- (instancetype)initWithValue:(nullable id)value node:(RLNode *)node block:(void (^)(_Nullable id value, _Nullable id source))block;

@end

NS_ASSUME_NONNULL_END
