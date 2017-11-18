//
//  NSNotificationCenter+RLNodeSupport.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLNode;
@interface NSNotificationCenter (RLNodeSupport)

- (RLNode *)rl_nodeForNotificationName:(NSString *)notificationName;
- (RLNode *)rl_nodeForNotificationName:(NSString *)notificationName object:(id)object;

@end
