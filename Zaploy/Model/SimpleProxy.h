//
//  SimpleProxy.h
//  Zaploy
//
//  Created by Dmitrii Trofimov on 08.04.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleProxy : NSObject

- (instancetype)initWithTarget:(NSObject *)target;

@end

NS_ASSUME_NONNULL_END
