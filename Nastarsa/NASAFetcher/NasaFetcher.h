//
//  NasaFetcher.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NASA_PHOTOS_ARRAY @"collection.items"
#define NASA_PHOTO_DATA @"data"


typedef NS_ENUM(NSInteger, NasaPhotoFormat) {
    NasaPhotoFormatThumb,    // thumbnail
//    NasaPhotoFormatSmall,    // small size
//    NasaPhotoFormatMedium,    // medium size
    NasaPhotoFormatLarge,    // large size
    NasaPhotoFormatOriginal    // original size
} ;


@interface NasaFetcher : NSObject

+ (NSURL *)URLforPhoto:(NSString *)link format:(NasaPhotoFormat)format;

@end
