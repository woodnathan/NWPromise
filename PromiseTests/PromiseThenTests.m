//
//  PromiseThenTests.m
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

@interface PromiseThenTests : XCTestCase

@end

@implementation PromiseThenTests

- (void)testPostChaining1
{
    NWPromise *p = [NWPromise promise];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"value", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

- (void)testPostChaining2
{
    NWPromise *p = [NWPromise promise];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [string uppercaseString];
    }).done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"VALUE", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

- (void)testPostChaining2OntoMain
{
    NWPromise *p = [NWPromise promise];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [string uppercaseString];
    }).onMainQueue.done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertTrue([NSThread isMainThread], @"Promise should be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"VALUE", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

#pragma mark Pre-resolution

- (void)testPreChaining1
{
    NWPromise *p = [NWPromise promise];
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"value", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

- (void)testPreChaining2
{
    NWPromise *p = [NWPromise promise];
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [string uppercaseString];
    }).done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"VALUE", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

- (void)testPreChaining2OntoMain
{
    NWPromise *p = [NWPromise promise];
    
    NSArray *input = @[ @"", @"value", @"" ];
    [p resolve:input];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSArray *strings) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [strings objectAtIndex:1];
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return [string uppercaseString];
    }).onMainQueue.done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertTrue([NSThread isMainThread], @"Promise should be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(@"VALUE", promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

#pragma mark Long Chain

- (void)testPostLongChain
{
    NWPromise *p = [NWPromise promise];
    
    NSString *input = @"value";
    [p resolve:input];
    
    __block NSString *promiseOutput = nil;
    p.then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).done(^(NSString *string) {
        promiseOutput = string;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects(input, promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isResolved], @"Promise should be rejected");
    XCTAssertFalse([p isRejected], @"Promise should not be rejected");
}

#pragma mark Rejection

- (void)testChainedPreRejection
{
    NWPromise *p = [NWPromise promise];
    
    NSError *input = [[NSError alloc] init];
    [p reject:input];
    
    __block NSError *promiseOutput = nil;
    p.then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).error(^(NSError *error) {
        promiseOutput = error;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertNotNil(promiseOutput, @"Output should not be nil");
    XCTAssertEqualObjects(input, promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isRejected], @"Promise should be rejected");
    XCTAssertFalse([p isResolved], @"Promise should not be resolved");
}

- (void)testChainedPostRejection
{
    NWPromise *p = [NWPromise promise];
    
    __block NSError *promiseOutput = nil;
    p.then((id)^(NSString *string) {
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        
        return string;
    }).error(^(NSError *error) {
        promiseOutput = error;
        
        XCTAssertFalse([NSThread isMainThread], @"Promise should not be called on main thead");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    NSError *input = [[NSError alloc] init];
    [p reject:input];
    
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertNotNil(promiseOutput, @"Output should not be nil");
    XCTAssertEqualObjects(input, promiseOutput, @"Objects not equal");
    XCTAssertTrue([p isRejected], @"Promise should be rejected");
    XCTAssertFalse([p isResolved], @"Promise should not be resolved");
}

@end
