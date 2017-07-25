//
//  RLLiberation.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLCScopedLiberation;

NS_ASSUME_NONNULL_BEGIN

@interface RLLiberation : NSObject

@property (atomic, assign, getter = isLiberated, readonly) BOOL liberated;

+ (instancetype)liberationWithBlock:(void (^)(void))block;

- (void)liberate;

- (RLCScopedLiberation *)asScopedLiberation;

@end

@interface RLScopedLiberation : RLLiberation

+ (instancetype)scopedWithLiberation:(RLLiberation *)liberation;

@end

NS_ASSUME_NONNULL_END
