//
//  RLFeedback+Private.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLFeedback.h"

NS_ASSUME_NONNULL_BEGIN

@class RLNode, RLLiberation;
@interface RLFeedback (Private)

@property (nonatomic, weak, readonly) RLNode *node;

@property (nonatomic, strong, readonly) RLLiberation *liberation;

+ (instancetype)feedbackValue:(nullable id)value node:(RLNode *)node liberation:(RLLiberation *)liberation;
- (instancetype)initWithValue:(nullable id)value node:(RLNode *)node liberation:(RLLiberation *)liberation;

@end

NS_ASSUME_NONNULL_END
