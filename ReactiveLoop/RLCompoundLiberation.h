//
//  RLLiberation.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLLiberation.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLCompoundLiberation : RLLiberation

+ (instancetype)compoundLiberation;

+ (instancetype)compoundLiberationWithLiberations:(nullable NSArray *)liberations;

- (void)addLiberation:(nullable RLLiberation *)liberation;

- (void)removeLiberation:(nullable RLLiberation *)liberation;

@end

NS_ASSUME_NONNULL_END
