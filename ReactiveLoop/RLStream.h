//
//  RLStream.h
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLStream, RLLiberation;
typedef RLStream * _Nullable (^RLStreamBindBlock)(id _Nullable value, BOOL *stop);

@protocol RLObserver;
@interface RLStream : NSObject

+ (RLStream *)create:(RLLiberation * (^)(id<RLObserver> observer))observeCompletion;

+ (__kindof RLStream *)never;

+ (__kindof RLStream *)empty;

+ (__kindof RLStream *)return:(nullable id)value;

+ (__kindof RLStream *)join:(id<NSFastEnumeration>)streams block:(RLStream * (^)(id, id))block;

+ (__kindof RLStream *)zip:(id<NSFastEnumeration>)streams;

+ (__kindof RLStream *)combineLatest:(id<NSFastEnumeration>)signals;

+ (__kindof RLStream *)merge:(id<NSFastEnumeration>)streams;

- (__kindof RLStream *)bind:(RLStreamBindBlock (^)(void))block;

- (__kindof RLStream *)flattenMap:(__kindof RLStream * _Nullable (^)(id _Nullable value))block;

- (__kindof RLStream *)map:(id _Nullable (^)(id _Nullable value))block;

- (__kindof RLStream *)mapReplace:(nullable id)object;

- (__kindof RLStream *)filter:(BOOL (^)(id _Nullable value))block;

- (__kindof RLStream *)ignore:(nullable id)value;

- (__kindof RLStream *)ignore;

- (__kindof RLStream *)zipWith:(RLStream *)stream;

- (__kindof RLStream *)takeUntil:(RLStream *)streamTrigger;

- (__kindof RLStream *)combineLatestWith:(RLStream *)stream;

- (__kindof RLStream *)merge:(RLStream *)stream;

- (__kindof RLStream *)doOutput:(void (^)(id value))block;
- (__kindof RLStream *)doComplet:(void (^)(void))block;

- (RLLiberation *)observe:(id<RLObserver>)observer;
- (RLLiberation *)observeOutput:(void (^)(id value))output;
- (RLLiberation *)observeOutput:(void (^)(id value))output completion:(void (^)())completion;

@end

@interface RLStream ()

@property (copy) NSString *name;

- (instancetype)setNameWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@end

NS_ASSUME_NONNULL_END
