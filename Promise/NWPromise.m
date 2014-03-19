//
//  NWPromise.m
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

#import "NWPromise.h"

typedef NS_ENUM(unsigned short, NWPromiseState) {
    NWPromiseIncomplete = 0,
    NWPromiseResolved,
    NWPromiseRejected,
};

static inline BOOL NWPromiseStateTransitionIsValid(NWPromiseState fromState, NWPromiseState toState)
{
    return (fromState == NWPromiseIncomplete && (toState == NWPromiseResolved || toState == NWPromiseRejected));
}

static NSString *const NWOperationPromiseFinishedKeyPath = @"isFinished";
static void *NWOperationPromiseFinishedKVOContext = &NWOperationPromiseFinishedKVOContext;

@interface NWOperationPromise : NWPromise

- (instancetype)initWithOperation:(NSOperation *)operation;

@property (nonatomic, strong) NSOperation *operation;

@end

@interface NWPromise () {
  @private
    dispatch_queue_t _queue;
    NSRecursiveLock *_lock;
    
    NWPromiseDoneBlock _doneBlock;
    NWPromiseDoneBlock _thenBlock;
    NWPromiseErrorBlock _errorBlock;
}

@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) NSRecursiveLock *lock;
@property (nonatomic, strong) NSSet *resolutionDependencies;
@property (nonatomic, strong) NSSet *rejectionDependencies; // Used to propagate rejection

@property (nonatomic, assign) NWPromiseState state;

@property (nonatomic, strong) id resolvedResult;
@property (nonatomic, strong) NSError *rejectedError;

- (void)addResolutionDependency:(NWPromise *)promise;
- (void)addRejectionDependency:(NWPromise *)promise;

- (void)executeResolution;
- (void)executeRejection;

@end

@implementation NWPromise

@synthesize queue = _queue;
@synthesize state = _state;

+ (NWPromise *)promise
{
    return [[self alloc] init];
}

#pragma mark Initializers

- (instancetype)init
{
    dispatch_queue_t q = dispatch_queue_create("promise", DISPATCH_QUEUE_SERIAL);
    return [self initWithQueue:q];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self)
    {
        self->_queue = queue;
        
        self->_lock = [[NSRecursiveLock alloc] init];
        
        self.resolutionDependencies = [NSSet set];
        self.rejectionDependencies = [NSSet set];
    }
    return self;
}

#pragma mark State

- (void)setState:(NWPromiseState)toState
{
    if (NWPromiseStateTransitionIsValid(self.state, toState) == NO)
        return;
    
    NSRecursiveLock *lock = self.lock;
    [lock lock];
    
    [self willChangeValueForKey:@"state"];
    self->_state = toState;
    [self didChangeValueForKey:@"state"];
    
    [lock unlock];
}

- (BOOL)isResolved
{
    NSRecursiveLock *lock = self.lock;
    [lock lock];
    BOOL isResolved = (self.state == NWPromiseResolved);
    [lock unlock];
    return isResolved;
}

- (BOOL)isRejected
{
    NSRecursiveLock *lock = self.lock;
    [lock lock];
    BOOL isRejected = (self.state == NWPromiseRejected);
    [lock unlock];
    return isRejected;
}

#pragma mark Block Properties

- (NWPromiseDoneProperty)done
{
    return ^(NWPromiseDoneBlock done) {
        self->_doneBlock = [done copy];
        
        if (done != nil && self.state == NWPromiseResolved)
            [self executeResolution];
        
        return self;
    };
}

- (NWPromiseThenProperty)then
{
    return ^(NWPromiseThenBlock then) {
        NWPromise *promise = self;
        if (then != nil)
        {
            promise = [NWPromise promise];
            
            self->_thenBlock = (id)^(id obj) {
                id result = then(obj);
                [promise resolve:result];
            };
            
            [self addRejectionDependency:promise];
            
            if (self.state == NWPromiseResolved)
            {
                [self executeResolution];
            }
            else
                if (self.state == NWPromiseRejected)
                {
                    [self executeRejection];
                }
        }
        else
        {
            self->_thenBlock = nil;
        }
        
        return promise;
    };
}

- (NWPromiseErrorProperty)error
{
    return ^(NWPromiseErrorBlock error) {
        
        self->_errorBlock = [error copy];
        
        if (error != nil && self.state == NWPromiseRejected)
            [self executeRejection];
        
        return self;
    };
}

#pragma mark Promise Resolution

- (void)resolve:(id)object
{
    if (self.state == NWPromiseIncomplete)
    {
        self.resolvedResult = object;
        [self executeResolution];
        
        self.state = NWPromiseResolved;
    }
}

- (void)reject:(NSError *)error
{
    if (self.state == NWPromiseIncomplete)
    {
        self.rejectedError = error;
        [self executeRejection];
        
        self.state = NWPromiseRejected;
    }
}

#pragma mark Dependencies

- (void)addResolutionDependency:(NWPromise *)promise
{
    NSParameterAssert(promise != nil);
    
    self.resolutionDependencies = [self.resolutionDependencies setByAddingObject:promise];
}

- (void)addRejectionDependency:(NWPromise *)promise
{
    NSParameterAssert(promise != nil);
    
    self.rejectionDependencies = [self.rejectionDependencies setByAddingObject:promise];
}

#pragma mark Execution

- (void)executeResolution
{
    id resolvedResult = self.resolvedResult;
    
    NWPromiseDoneBlock thenBlock = self->_thenBlock;
    if (thenBlock)
    {
        self->_thenBlock = nil;
        dispatch_async(self.queue, ^{
            thenBlock(resolvedResult);
        });
    }
    
    NWPromiseDoneBlock doneBlock = self->_doneBlock;
    if (doneBlock)
    {
        self->_doneBlock = nil;
        dispatch_async(self.queue, ^{
            doneBlock(resolvedResult);
        });
    }
    
    [self.resolutionDependencies makeObjectsPerformSelector:@selector(resolve:)
                                                 withObject:resolvedResult];
}

- (void)executeRejection
{
    NSError *rejectedError = self.rejectedError;
    
    NWPromiseErrorBlock errorBlock = self->_errorBlock;
    if (errorBlock)
    {
        self->_errorBlock = nil;
        dispatch_async(self.queue, ^{
            errorBlock(rejectedError);
        });
    }
    
    [self.rejectionDependencies makeObjectsPerformSelector:@selector(reject:)
                                                withObject:rejectedError];
}

#pragma mark Main Queue

- (NWPromise *)onQueue:(dispatch_queue_t)queue
{
    NSParameterAssert(queue != nil);
    
    NWPromise *p = [[NWPromise alloc] initWithQueue:queue];
    
    // Needed for pre-resolution/rejection
    // Where the promise is resolved/rejected before given a block
    p.state = self.state;
    p.resolvedResult = self.resolvedResult;
    p.rejectedError = self.rejectedError;
    
    [self addResolutionDependency:p];
    [self addRejectionDependency:p];
    
    return p;
}

- (NWPromise *)onMainQueue
{
    return [self onQueue:dispatch_get_main_queue()];
}

@end

@implementation NWOperationPromise

- (instancetype)initWithOperation:(NSOperation *)operation
{
    self = [super init];
    if (self)
    {
        self.operation = operation;
        
        [operation addObserver:self
                    forKeyPath:NWOperationPromiseFinishedKeyPath
                       options:0
                       context:NWOperationPromiseFinishedKVOContext];
    }
    return self;
}

- (void)dealloc
{
    [self.operation removeObserver:self
                        forKeyPath:NWOperationPromiseFinishedKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == NWOperationPromiseFinishedKVOContext)
    {
        [self resolve:self.operation];
    }
}

@end

@implementation NSOperation (NWPromise)

- (NWPromise *)promise
{
    return [[NWOperationPromise alloc] initWithOperation:self];
}

@end
