NWPromise
============

An Objective-C promise library with support for NSOperation implemented as a DSL

### Example
```
NWPromise *p = [NWPromise promise];
p.done(^(NSString *result) {
	NSLog(@"Result: %@", result);
});

[p resolve:@"Example string"];
```

### Todo
- Documentation
- Review Threading
- NSOperation only supports resolution at the moment