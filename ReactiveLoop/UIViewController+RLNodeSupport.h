//
//  UIViewController+RLNodeSupport.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLNode;
@interface UIViewController (RLNodeSupport)

@property (nonatomic, strong, readonly) RLNode *rl_viewDidLoadNode;

@property (nonatomic, strong, readonly) RLNode *rl_viewWillAppearNode;

@property (nonatomic, strong, readonly) RLNode *rl_viewDidAppearNode;

@property (nonatomic, strong, readonly) RLNode *rl_viewWillDisappearNode;

@property (nonatomic, strong, readonly) RLNode *rl_viewDidDisappearNode;

@end
