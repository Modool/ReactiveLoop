//
//  NSObject+RLSelectorStream.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/28.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMacros.h"

NS_ASSUME_NONNULL_BEGIN

RL_EXTERN NSString * const RLSelectorStreamErrorDomain;
RL_EXTERN const NSInteger RLSelectorStreamErrorMethodSwizzlingRace;

@class RLStream;

@interface NSObject (RLSelectorStream)

- (RLStream *)rl_streamForSelector:(SEL)selector;

- (RLStream *)rl_streamForSelector:(SEL)selector fromProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
