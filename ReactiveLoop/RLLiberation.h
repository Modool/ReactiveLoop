//
//  RLLiberation.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLCScopedLiberation;
@interface RLLiberation : NSObject

@property (atomic, assign, getter = isLiberated, readonly) BOOL liberated;

+ (instancetype)liberationWithBlock:(void (^)(void))block;

- (void)liberate;

- (RLCScopedLiberation *)asScopedLiberation;

@end

@interface RLScopedLiberation : RLLiberation

+ (instancetype)scopedWithLiberation:(RLLiberation *)liberation;

@end

@interface RLCompoundLiberation : RLLiberation

+ (instancetype)compoundLiberation;

+ (instancetype)compoundLiberationWithLiberations:(nullable NSArray *)liberations;

- (void)addLiberation:(nullable RLLiberation *)liberation;

- (void)removeLiberation:(nullable RLLiberation *)liberation;

@end

@interface RLSerialLiberation : RLLiberation

@property (atomic, strong, nullable) RLLiberation *liberation;

+ (instancetype)serialLiberationWithLiberation:(nullable RLLiberation *)liberation;

- (nullable RLLiberation *)swapInLiberation:(nullable RLLiberation *)newLiberation;

@end

NS_ASSUME_NONNULL_END
