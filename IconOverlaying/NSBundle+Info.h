//
//  NSBundle+Info.h
//  IconOverlaying
//
//  Created by Damian Rzeszot on 26/11/2018.
//  Copyright © 2018 pixle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Info)
- (NSString *)version;
- (NSString *)build;
@end

NS_ASSUME_NONNULL_END
