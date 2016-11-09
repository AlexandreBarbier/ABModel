//
//  Reflexion.m
//  ABModel
//
//  Created by Alexandre barbier on 09/11/2016.
//  Copyright © 2016 abarbier. All rights reserved.
//
#import <objc/runtime.h>
#import "Reflection.h"

@implementation Reflection

+ (Class) getTypeOf:(id)var {
    return NSClassFromString([NSString stringWithCString:ivar_getTypeEncoding((__bridge Ivar)(var)) encoding:NSUTF8StringEncoding]);
}


@end
