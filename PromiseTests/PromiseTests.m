//
//  PromiseTests.m
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

@interface PromiseTests : XCTestCase

@end

@implementation PromiseTests

- (void)testPreResolution
{
    NWPromise *p = [NWPromise promise];
    
    NSString *obj = @"";
    [p resolve:obj];
    
    __block NSError *promiseObj = nil;
    p.done(^(id obj) {
        promiseObj = obj;
        
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
    
    __block NSError *promiseObj = nil;
    p.done(^(id obj) {
        promiseObj = obj;
        
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

#pragma mark Rejection

- (void)testPreRejection
{
    NWPromise *p = [NWPromise promise];
    
    NSError *error = [NSError new];
    [p reject:error];
    
    __block NSError *promiseError = nil;
    p.error(^(NSError *error) {
        promiseError = error;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(error, promiseError, @"Objects not equal");
    XCTAssertTrue([p isRejected], @"Promise should be rejected");
    XCTAssertFalse([p isResolved], @"Promise should not be resolved");
}

- (void)testPostRejection
{
    NWPromise *p = [NWPromise promise];
    
    __block NSError *promiseError = nil;
    p.error(^(NSError *error) {
        promiseError = error;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSError *error = [NSError new];
    [p reject:error];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(error, promiseError, @"");
    XCTAssertTrue([p isRejected], @"Promise should be rejected");
    XCTAssertFalse([p isResolved], @"Promise should not be resolved");
}

@end
