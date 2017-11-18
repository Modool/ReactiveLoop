//
//  RLFeedback.h
//  ReactiveLoop
//
//  Created by xulinfeng on 2017/11/18.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLFeedback : NSObject

@property (nonatomic, strong, readonly, nullable) id value;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
