//
//  NWPromise.h
//
//  Copyright (c) 2014 Nathan Wood (http://www.woodnathan.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class NWPromise;

typedef id(^NWPromiseThenBlock)(id obj);
typedef NWPromise *(^NWPromiseThenProperty)(NWPromiseThenBlock then);
typedef void(^NWPromiseDoneBlock)(id obj);
typedef NWPromise *(^NWPromiseDoneProperty)(NWPromiseDoneBlock done);
typedef void(^NWPromiseErrorBlock)(NSError *error);
typedef NWPromise *(^NWPromiseErrorProperty)(NWPromiseErrorBlock error);

@interface NWPromise : NSObject

+ (NWPromise *)promise;

@property (nonatomic, readonly, getter = isResolved) BOOL resolved;
@property (nonatomic, readonly, getter = isRejected) BOOL rejected;

@property (nonatomic, readonly) NWPromiseThenProperty then;
@property (nonatomic, readonly) NWPromiseDoneProperty done;
@property (nonatomic, readonly) NWPromiseErrorProperty error;

- (void)resolve:(id)object;
- (void)reject:(NSError *)error;

- (NWPromise *)onQueue:(dispatch_queue_t)queue;
- (NWPromise *)onMainQueue;

@end

@interface NSOperation (NWPromise)

- (NWPromise *)promise;

@end

