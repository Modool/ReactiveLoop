//
//  RLStream.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLStream : NSObject

+ (__kindof RLStream *)empty;

+ (__kindof RLStream *)return:(nullable id)value;

typedef RLStream * _Nullable (^RLStreamBindBlock)(id _Nullable value, BOOL *stop);

- (__kindof RLStream *)bind:(RLStreamBindBlock (^)(void))block;

- (__kindof RLStream *)flattenMap:(__kindof RLStream * _Nullable (^)(id _Nullable value))block;

- (__kindof RLStream *)map:(id _Nullable (^)(id _Nullable value))block;

- (__kindof RLStream *)mapReplace:(nullable id)object;

- (__kindof RLStream *)filter:(BOOL (^)(id _Nullable value))block;

- (__kindof RLStream *)ignore:(nullable id)value;

- (__kindof RLStream *)ignore;

@end

@interface RLStream ()

@property (copy) NSString *name;

- (instancetype)setNameWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@end

NS_ASSUME_NONNULL_END
