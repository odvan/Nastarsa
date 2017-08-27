//
//  ImagesCache.h
//  Nastarsa
//
//  Created by Artur Kablak on 27/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImagesCache : NSObject


+ (ImagesCache *)sharedInstance;

// set
- (void)cacheImage:(UIImage *)image forKey:(NSURL *)key;
// get
- (UIImage *)getCachedImageForKey:(NSURL *)key;

@end
