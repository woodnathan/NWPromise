//
//  PromiseQueueTests.m
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

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "NWPromise.h"

static NSTimeInterval DEFAULT_TIMEOUT = 0.5;

@interface PromiseQueueTests : XCTestCase

@end

@implementation PromiseQueueTests

- (void)testPreResolution
{
    NWPromise *p = [NWPromise promise];
    
    NSString *obj = @"";
    [p resolve:obj];
    
    dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
    NWPromise *qp = [p onQueue:queue];
    
    __block NSError *promiseObj = nil;
    qp.done(^(id obj) {
        promiseObj = obj;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(dispatch_queue_get_label(dispatch_get_current_queue()), dispatch_queue_get_label(queue), @"Promise queue is not what it should be");
#pragma clang diagnostic pop
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(obj, promiseObj, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be resolved");
    XCTAssertFalse([p isRejected], @"Promise should be not rejected");
}

- (void)testPostResolution
{
    NWPromise *p = [NWPromise promise];
    
    dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
    NWPromise *qp = [p onQueue:queue];
    
    __block NSError *promiseObj = nil;
    qp.done(^(id obj) {
        promiseObj = obj;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(dispatch_queue_get_label(dispatch_get_current_queue()), dispatch_queue_get_label(queue), @"Promise queue is not what it should be");
#pragma clang diagnostic pop
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSString *obj = @"";
    [p resolve:obj];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(obj, promiseObj, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be resolved");
    XCTAssertFalse([p isRejected], @"Promise should be not rejected");
}

@end
