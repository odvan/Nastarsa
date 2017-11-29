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


+ (NSString *)URLStringForPhoto:(NSString *)link format:(NasaPhotoFormat)format {
    
    NSString *formatString = link;
    switch (format) {
        case NasaPhotoFormatThumb:    formatString = [NSString stringWithFormat:@"%@~thumb", link]; break;
        case NasaPhotoFormatLarge:     formatString = [NSString stringWithFormat:@"%@~large", link]; break;
        case NasaPhotoFormatOriginal:  formatString = [NSString stringWithFormat:@"%@~orig", link]; break;
    }
    return [NSString stringWithFormat:@"http://images-assets.nasa.gov/image/%@/%@.jpg", link, formatString];
}


+ (NSURL *)URLforPhoto:(NSString *)link format:(NasaPhotoFormat)format {
    return [NSURL URLWithString:[NasaFetcher URLStringForPhoto:link format:format]];
}


+ (NSString *)URLforSearch:(NSString *)text {
    if (!text) {
        NSLog(@"DEMO URL");
        return [NSString stringWithFormat:DEMO_URL];
    }
    NSString *searchWord;
    if ([text rangeOfString:@"%20"].location != NSNotFound) {
        searchWord = [NSString stringWithFormat:BASE_URL_MULTIPLE_WORDS@"%@", text];
    } else {
        searchWord = [NSString stringWithFormat:BASE_URL@"%@", text];
    }
    return searchWord;
}


+ (NSString *)URLforSearch:(NSString *)text withPage:(int)number {
    if (!text) {
        NSLog(@"DEMO URL page number");
        return [NSString stringWithFormat:DEMO_URL@"&page=%d", number];
    }
    return [NSString stringWithFormat:BASE_URL@"%@&page=%d", text, number];
}


+ (void)pageNumbersFrom:(NSString *)searchText withCompletion:(void (^)(BOOL success, int numbers))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURL *url = [NSURL URLWithString:[NasaFetcher URLforSearch:searchText]]; // url for pictures
    dispatch_queue_t fetchQ = dispatch_queue_create("base fetcher", NULL);
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Nasa
        NSData *jsonResults = [NSData dataWithContentsOfURL: url];
        NSError *error;
        int numberOfPages = 0;
        
        if (jsonResults) {
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
                completion(YES, numberOfPages);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSLog(@"getting pages error");
                completion(NO, numberOfPages);
            });;
        }
        
    });
}


+ (void)fetchPhotos:(NSString *)searchText pageNumber:(int)page withCompletion:(void (^)(BOOL success, NSMutableArray *photosData))completion {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSLog(@"page number: %d", page);
    NSURL *url = [[NSURL alloc] initWithString:[NasaFetcher URLforSearch:searchText withPage:page]];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("nasa fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Nasa
        NSData *jsonResults = [NSData dataWithContentsOfURL: url];
        NSError *error;
        
        if (jsonResults) {
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
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSLog(@"json DATA error");
                completion(NO, nil);
            });;
        }
    });
}

@end
