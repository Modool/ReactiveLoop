//
//  RLEvent.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "RLStream.h"
#import "RLObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLEvent : RLStream<RLObserver>

+ (instancetype)event;

@end

@interface RLReplayEvent : RLEvent

@end

NS_ASSUME_NONNULL_END
