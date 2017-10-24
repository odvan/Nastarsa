//
//  NasaFetcher.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageModel.h"

#define NASA_PHOTOS_NUMBER @"collection.metadata.total_hits"
#define NASA_PHOTOS_ARRAY @"collection.items"
#define NASA_PHOTO_DATA @"data"
#define BASE_URL @"https://images-api.nasa.gov/search?year_start=2017&year_end=2017&media_type=image"
#define DEMO_URL @"https://images-api.nasa.gov/search?q=apollo&media_type=image"


typedef NS_ENUM(NSInteger, NasaPhotoFormat) {
    NasaPhotoFormatThumb,    // thumbnail
//    NasaPhotoFormatSmall,    // small size
//    NasaPhotoFormatMedium,    // medium size
    NasaPhotoFormatLarge,    // large size
    NasaPhotoFormatOriginal    // original size
} ;


@interface NasaFetcher : NSObject

+ (NSString *)URLStringForPhoto:(NSString *)link format:(NasaPhotoFormat)format;
+ (NSURL *)URLforPhoto:(NSString *)link format:(NasaPhotoFormat)format;
+ (void)pageNumbers:(void (^)(int numbers))completion;
+ (void)fetchPhotos:(int)pageNumber withCompletion:(void (^)(BOOL success, NSMutableArray *photosData))completion;

@end
