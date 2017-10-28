//
//  RLNode.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"

@class RLLiberation, RLRule;

NS_ASSUME_NONNULL_BEGIN

@interface RLNode : NSObject

@property (nonatomic, assign, readonly) BOOL enabled;

@property (nonatomic, strong, readonly) id value;

+ (instancetype)node;
+ (instancetype)nodeWithRule:(RLRule *)rule;
+ (instancetype)nodeWithRules:(NSArray<RLRule *> *)rules;

@end

@interface RLNode (RLSubNode)

@property (strong, readonly) RLRule *rule;

- (void)restrainRule:(__kindof RLRule *)rule;
- (void)unrestrainRule:(__kindof RLRule *)rule;

@end

@interface RLNode (RLObserve)

- (__kindof RLLiberation *)feedback:(void (^)())block;
- (__kindof RLLiberation *)feedbackWithError:(void (^)(NSError *error))errorBlock;
- (__kindof RLLiberation *)feedback:(void (^)())block error:(void (^)(NSError *error))errorBlock;

@end

@interface RLNilNode : RLNode

+ (instancetype)nilNode;

@end

NS_ASSUME_NONNULL_END
