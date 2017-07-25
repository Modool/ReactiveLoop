//
//  RLLiberation.m
//  ReactiveLoop
//
//  Created by Jave on 2017/7/25.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <pthread/pthread.h>
#import <CoreFoundation/CoreFoundation.h>

#import "RLCompoundLiberation.h"

#define RLCompoundLiberationInlineCount 2

static CFMutableArrayRef RLCreateLiberationsArray(void) {
    
	CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
	callbacks.equal = NULL;

	return CFArrayCreateMutable(NULL, 0, &callbacks);
}

@interface RLCompoundLiberation () {
	pthread_mutex_t _mutex;

	#if RLCompoundLiberationInlineCount
    
	RLLiberation *_inlineLiberations[RLCompoundLiberationInlineCount];

	#endif
    
	CFMutableArrayRef _liberations;
    
	BOOL _liberated;
}

@end

@implementation RLCompoundLiberation

#pragma mark Properties

- (BOOL)isLiberated {
	pthread_mutex_lock(&_mutex);
	BOOL liberated = _liberated;
	pthread_mutex_unlock(&_mutex);

	return liberated;
}

#pragma mark Lifecycle

+ (instancetype)compoundLiberation {
	return [[self alloc] initWithLiberations:nil];
}

+ (instancetype)compoundLiberationWithLiberations:(NSArray *)liberations {
	return [[self alloc] initWithLiberations:liberations];
}

- (instancetype)init {
	self = [super init];

	const int result __attribute__((unused)) = pthread_mutex_init(&_mutex, NULL);
	NSCAssert(0 == result, @"Failed to initialize mutex with error %d.", result);

	return self;
}

- (instancetype)initWithLiberations:(NSArray *)otherLiberations {
	self = [self init];

	#if RLCompoundLiberationInlineCount
	[otherLiberations enumerateObjectsUsingBlock:^(RLLiberation *liberation, NSUInteger index, BOOL *stop) {
		self->_inlineLiberations[index] = liberation;

		// Stop after this iteration if we've reached the end of the inlined
		// array.
		if (index == RLCompoundLiberationInlineCount - 1) *stop = YES;
	}];
	#endif

	if (otherLiberations.count > RLCompoundLiberationInlineCount) {
		_liberations = RLCreateLiberationsArray();

		CFRange range = CFRangeMake(RLCompoundLiberationInlineCount, (CFIndex)otherLiberations.count - RLCompoundLiberationInlineCount);
		CFArrayAppendArray(_liberations, (__bridge CFArrayRef)otherLiberations, range);
	}

	return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
	RLLiberation *liberation = [RLLiberation liberationWithBlock:block];
	return [self initWithLiberations:@[ liberation ]];
}

- (void)dealloc {
	#if RLCompoundLiberationInlineCount
	for (unsigned i = 0; i < RLCompoundLiberationInlineCount; i++) {
		_inlineLiberations[i] = nil;
	}
	#endif

	if (_liberations != NULL) {
		CFRelease(_liberations);
		_liberations = NULL;
	}

	const int result __attribute__((unused)) = pthread_mutex_destroy(&_mutex);
	NSCAssert(0 == result, @"Failed to destroy mutex with error %d.", result);
}

#pragma mark Addition and Removal

- (void)addLiberation:(RLLiberation *)liberation {
	NSCParameterAssert(liberation != self);
	if (liberation == nil || liberation.liberated) return;

	BOOL shouldLiberate = NO;

	pthread_mutex_lock(&_mutex);
	{
		if (_liberated) {
			shouldLiberate = YES;
		} else {
			#if RLCompoundLiberationInlineCount
			for (unsigned i = 0; i < RLCompoundLiberationInlineCount; i++) {
				if (_inlineLiberations[i] == nil) {
					_inlineLiberations[i] = liberation;
					goto foundSlot;
				}
			}
			#endif

			if (_liberations == NULL) _liberations = RLCreateLiberationsArray();
			CFArrayAppendValue(_liberations, (__bridge void *)liberation);

		#if RLCompoundLiberationInlineCount
		foundSlot:;
		#endif
		}
	}
	pthread_mutex_unlock(&_mutex);

	// Performed outside of the lock in case the compound liberation is used
	// recursively.
	if (shouldLiberate) [liberation liberate];
}

- (void)removeLiberation:(RLLiberation *)liberation {
	if (liberation == nil) return;

	pthread_mutex_lock(&_mutex);
	{
		if (!_liberated) {
			#if RLCompoundLiberationInlineCount
			for (unsigned i = 0; i < RLCompoundLiberationInlineCount; i++) {
				if (_inlineLiberations[i] == liberation) _inlineLiberations[i] = nil;
			}
			#endif

			if (_liberations != NULL) {
				CFIndex count = CFArrayGetCount(_liberations);
				for (CFIndex i = count - 1; i >= 0; i--) {
					const void *item = CFArrayGetValueAtIndex(_liberations, i);
					if (item == (__bridge void *)liberation) {
						CFArrayRemoveValueAtIndex(_liberations, i);
					}
				}
			}
		}
	}
	pthread_mutex_unlock(&_mutex);
}

#pragma mark RLLiberation

static void liberateEach(const void *value, void *context) {
	RLLiberation *liberation = (__bridge id)value;
	[liberation liberate];
}

- (void)liberate {
	#if RLCompoundLiberationInlineCount
	RLLiberation *inlineCopy[RLCompoundLiberationInlineCount];
	#endif

	CFArrayRef remainingLiberations = NULL;

	pthread_mutex_lock(&_mutex);
	{
		_liberated = YES;

		#if RLCompoundLiberationInlineCount
		for (unsigned i = 0; i < RLCompoundLiberationInlineCount; i++) {
			inlineCopy[i] = _inlineLiberations[i];
			_inlineLiberations[i] = nil;
		}
		#endif

		remainingLiberations = _liberations;
		_liberations = NULL;
	}
	pthread_mutex_unlock(&_mutex);

	#if RLCompoundLiberationInlineCount
	// Liberate outside of the lock in case the compound liberation is used
	// recursively.
	for (unsigned i = 0; i < RLCompoundLiberationInlineCount; i++) {
		[inlineCopy[i] liberate];
	}
	#endif

	if (remainingLiberations == NULL) return;

	CFIndex count = CFArrayGetCount(remainingLiberations);
	CFArrayApplyFunction(remainingLiberations, CFRangeMake(0, count), &liberateEach, NULL);
	CFRelease(remainingLiberations);
}

@end
