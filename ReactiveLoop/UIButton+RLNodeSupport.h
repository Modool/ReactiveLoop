//
//  UIButton+RLNodeSupport.h
//  ReactiveLoopDemo
//
//  Created by xulinfeng on 2017/10/29.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLNode;
@interface UIButton (RLNodeSupport)

// The default node.
@property (nonatomic, strong, readonly) RLNode *rl_node;

@end
