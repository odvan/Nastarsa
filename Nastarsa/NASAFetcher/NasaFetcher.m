//
//  NasaFetcher.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NasaFetcher.h"
#import <UIKit/UIKit.h>

@implementation NasaFetcher


+ (NSString *)urlStringForPhoto:(NSString *)link format:(NasaPhotoFormat)format {
    
    NSString *formatString = link;
    switch (format) {
        case NasaPhotoFormatThumb:    formatString = [NSString stringWithFormat:@"%@~thumb", link]; break;
        case NasaPhotoFormatLarge:     formatString = [NSString stringWithFormat:@"%@~large", link]; break;
        case NasaPhotoFormatOriginal:  formatString = [NSString stringWithFormat:@"%@~orig", link]; break;
    }
    return [NSString stringWithFormat:@"http://images-assets.nasa.gov/image/%@/%@.jpg", link, formatString];
}

+ (NSURL *)URLforPhoto:(NSString *)link format:(NasaPhotoFormat)format {
    return [NSURL URLWithString:[NasaFetcher urlStringForPhoto:link format:format]];
}

+ (void)pageNumbers:(void (^)(int numbers))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURL *url = [[NSURL alloc] initWithString: BASE_URL]; // url for pictures
    dispatch_queue_t fetchQ = dispatch_queue_create("base fetcher", NULL);
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Nasa
        NSData *jsonResults = [NSData dataWithContentsOfURL: url];
        NSError *error;
        int numberOfPages = 0;
        
        // convert it to a Property List (NSArray and NSDictionary)
        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                options:0
                                                                  error:&error];
        
        if (error) {
            NSLog(@"Error parsing JSON: %@", error);
        }
        else {
            if ([results isKindOfClass:[NSDictionary class]]) {
                NSLog(@"it is a dictionary!");
                
                int photoCount = [[results valueForKeyPath: NASA_PHOTOS_NUMBER] intValue];
                NSLog(@"numbers of photo: %d", photoCount);
                
                if (photoCount) {
                    int page = photoCount % 100;
                    if (page > 0) {
                        numberOfPages = photoCount/100 + 1;
                    } else {
                        numberOfPages = photoCount/100;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            completion(numberOfPages);
        });
        
    });
}

+ (void)fetchPhotos:(int)pageNumber withCompletion:(void (^)(BOOL success, NSMutableArray *photosData))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSLog(@"page number: %d", pageNumber);
    NSString *urlWithPage = [NSString stringWithFormat:BASE_URL@"&page=%d", pageNumber];
    NSURL *url = [[NSURL alloc] initWithString: urlWithPage];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("nasa fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Nasa
        NSData *jsonResults = [NSData dataWithContentsOfURL: url];
        NSError *error;
        
        // convert it to a Property List (NSArray and NSDictionary)
        NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:&error];
        
        if (error) {
            NSLog(@"Error parsing JSON: %@", error);
            // update the Model (and thus our UI), but do so back on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                completion(NO, nil);
            });
        }
        else {
            if ([propertyListResults isKindOfClass:[NSDictionary class]]) {
                NSLog(@"it is an array!");
                
                // get the NSArray of photo NSDictionarys out of the results
                NSMutableArray *photosData = [propertyListResults valueForKeyPath: NASA_PHOTOS_ARRAY];
                
                if (photosData) {
                    // update the Model (and thus our UI), but do so back on the main queue
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        completion(YES, photosData);
                    });
                }
            }
        }
    });
}
@end
