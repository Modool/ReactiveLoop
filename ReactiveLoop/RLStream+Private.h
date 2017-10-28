//
//  RLStream+Private.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"

@interface RLEmptyStream : RLStream

+ (RLStream *)empty;

@end

@interface RLReturnStream : RLStream

+ (RLStream *)return:(id)value;

@end

@interface RLDynamicStream : RLStream

+ (RLStream *)create:(RLLiberation * (^)(id<RLObserver> observer))observeCompletion;

@end
