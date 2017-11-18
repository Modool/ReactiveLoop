//
//  UIGestureRecognizer+RLNodeSupport.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLNode;
@interface UIGestureRecognizer (RLNodeSupport)

@property (nonatomic, strong, readonly) RLNode *rl_stateNode;

- (RLNode *)rl_nodeForState:(UIGestureRecognizerState)state;

@end
