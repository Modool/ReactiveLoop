//
//  RLNode.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"

@class RLLiberation, RLRule, RLFeedback;

NS_ASSUME_NONNULL_BEGIN

@interface RLNode : NSObject

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, strong, readonly) id value;

@property (nonatomic, assign) BOOL enabled;

+ (instancetype)node;
+ (instancetype)nodeWithRule:(RLRule *)rule;
+ (instancetype)nodeWithRules:(NSArray<RLRule *> *)rules;

- (instancetype)setNameWithFormat:(NSString *)format, ...;

@end

@interface RLNode (RLSubNode)

@property (nonatomic, strong, readonly) RLRule *rule;

@end

@interface RLNode (RLNodeInfo)

@property (nonatomic, strong, readonly) RLStream *relatedInfoStream;

- (void)attachStream:(RLStream *)info;

@end

@interface RLNode (RLeedbackObserve)

- (RLFeedback *)feedbackObserve:(void (^)(id value))block;

@end

@interface RLNilNode : RLNode

+ (instancetype)nilNode;

@end

NS_ASSUME_NONNULL_END
