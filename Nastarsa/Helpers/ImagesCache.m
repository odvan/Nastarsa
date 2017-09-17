//
//  ImagesCache.m
//  Nastarsa
//
//  Created by Artur Kablak on 27/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImagesCache.h"



static ImagesCache *sharedInstance;

@interface ImagesCache ()

@property (nonatomic, strong) NSCache *imagesCache;

@end


@implementation ImagesCache

+ (ImagesCache *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ImagesCache alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.imagesCache = [[NSCache alloc] init];
        [self.imagesCache setCountLimit:100];
    }
    return self;
}

- (void)cacheImage:(UIImage *)image forKey:(NSString *)key {
    [self.imagesCache setObject:image forKey:key];
}

- (UIImage *)getCachedImageForKey:(NSString *)key {
    return [self.imagesCache objectForKey:key];
}


@end
