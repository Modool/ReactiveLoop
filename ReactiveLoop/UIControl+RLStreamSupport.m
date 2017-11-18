//
//  UIControl+RLStreamSupport.m
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import "UIControl+RLStreamSupport.h"
#import "RLStream.h"
#import "RLObserver.h"
#import "RLLiberation.h"
#import "NSObject+RLDeallocating.h"

#import "RLEXTScope.h"

@implementation UIControl (RLStreamSupport)

- (RLStream *)rl_signalForControlEvents:(UIControlEvents)controlEvents {
    @weakify(self);
    return [[RLStream create:^RLLiberation *(id<RLObserver> observer) {
        @strongify(self);
        [self addTarget:observer action:@selector(output:) forControlEvents:controlEvents];
        
        RLLiberation *liberation = [RLLiberation liberationWithBlock:^{
            [observer complete];
        }];
        [self.rl_deallocLiberation addLiberation:liberation];
        
        return [RLLiberation liberationWithBlock:^{
            @strongify(self);
            [self.rl_deallocLiberation removeLiberation:liberation];
            [self removeTarget:observer action:@selector(output:) forControlEvents:controlEvents];
        }];
    }] setNameWithFormat:@"%@ -rl_signalForControlEvents: %lx", self, (unsigned long)controlEvents];
}

@end
