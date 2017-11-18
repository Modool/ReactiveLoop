//
//  UIView+RLNodeSupport.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLNode;
@interface UIView (RLNodeSupport)

@property (nonatomic, strong, readonly) RLNode *rl_moveInSuperviewNode;

@property (nonatomic, strong, readonly) RLNode *rl_moveOutSuperviewNode;

@property (nonatomic, strong, readonly) RLNode *rl_layoutSubviewsNode;

@end
