//
//  IXSWrapper.h
//  ios-iCONex
//
//  Created by Jeonghwan Ahn on 09/07/2018.
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IXSWrapper : NSObject

+ (void)systemCheck: (NSError **)error;
+ (int)detectDebugger;
+ (void)intigrityCheck: (NSError **)error;
+ (void)setDebug;

@end
