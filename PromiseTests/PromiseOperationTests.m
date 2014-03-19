//
//  PromiseOperationTests.m
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

@interface PromiseOperationTests : XCTestCase

@end

@implementation PromiseOperationTests

- (void)testResolution
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i < 100; i++)
            [items addObject:@(i)];
    }];
    
    NWPromise *p = [operation promise];
    
    __block id lastObject = nil;
    p.done(^(id obj) {
        lastObject = [items lastObject];
        
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [operation start];
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects([items lastObject], lastObject, @"Objects should be equal");
}

- (void)testChainedResolution
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i < 100; i++)
            [items addObject:@(i)];
    }];
    
    NWPromise *p = [operation promise];
    
    __block id lastObject = nil;
    p.then((id)^(__unused NSOperation *operation) {
        return [items subarrayWithRange:NSMakeRange(10, 10)];
    }).done(^(id obj) {
        lastObject = [obj lastObject];
        
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [operation start];
    [self waitForTimeout:DEFAULT_TIMEOUT];
    
    XCTAssertEqualObjects([[items subarrayWithRange:NSMakeRange(10, 10)] lastObject], lastObject, @"Objects should be equal");
}

@end
