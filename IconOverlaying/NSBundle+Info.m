//
//  NSBundle+Info.m
//  IconOverlaying
//
//  Created by Damian Rzeszot on 26/11/2018.
//  Copyright © 2018 pixle. All rights reserved.
//

#import "NSBundle+Info.h"

@implementation NSBundle (Info)

- (NSString *)version
{
    return self.infoDictionary[@"CFBundleShortVersionString"];
}

- (NSString *)build
{
    return self.infoDictionary[@"CFBundleVersion"];
}

@end
