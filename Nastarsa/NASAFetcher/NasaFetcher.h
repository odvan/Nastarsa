//
//  NasaFetcher.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NASA_PHOTOS_NUMBER @"collection.metadata.total_hits"
#define NASA_PHOTOS_ARRAY @"collection.items"
#define NASA_PHOTO_DATA @"data"
#define DEMO_URL @"https://images-api.nasa.gov/search?year_start=2018&year_end=2018&media_type=image"
#define BASE_URL @"https://images-api.nasa.gov/search?year_start=1920&year_end=2017&media_type=image&title="
#define BASE_URL_MULTIPLE_WORDS @"https://images-api.nasa.gov/search?year_start=1920&year_end=2017&media_type=image&q="

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

+ (NSString *)URLforSearch:(NSString *)text withPage:(int)number;
+ (NSString *)URLforSearch:(NSString *)text;

+ (void)pageNumbersFrom:(NSString *)searchText withCompletion:(void (^)(BOOL success, int numbers))completion;
+ (void)fetchPhotos:(NSString *)searchText pageNumber:(int)page withCompletion:(void (^)(BOOL success, NSMutableArray *photosData))completion;

@end
