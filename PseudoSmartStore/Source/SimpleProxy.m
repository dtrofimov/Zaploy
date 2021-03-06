//
//  SimpleProxy.m
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

#import "SimpleProxy.h"

@implementation SimpleProxy

- (instancetype)initWithTarget:(NSObject *)target {
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *result = [self.target methodSignatureForSelector:aSelector];
    return result;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [self willForwardSelector:anInvocation.selector];
    [anInvocation invokeWithTarget:self.target];
}

- (void)willForwardSelector:(SEL)selector {
}

@end
