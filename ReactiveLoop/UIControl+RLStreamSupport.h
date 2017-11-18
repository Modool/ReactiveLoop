//
//  UIControl+RLStreamSupport.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLStream;
@interface UIControl (RLStreamSupport)

- (RLStream *)rl_signalForControlEvents:(UIControlEvents)controlEvents;

@end
