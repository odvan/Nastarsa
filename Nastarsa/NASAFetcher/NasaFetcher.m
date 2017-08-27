//
//  NasaFetcher.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NasaFetcher.h"

@implementation NasaFetcher


//+ (NSURL *)URLForQuery:(NSString *)query
//{
//    query = [NSString stringWithFormat:@"%@&format=json&nojsoncallback=1&api_key=%@", query, FlickrAPIKey];
//    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    return [NSURL URLWithString:query];
//}

//+ (UIImage *)imageFrom:(NSURL *)link {
    
//}

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
    
    return [NSURL URLWithString:[self urlStringForPhoto:link format:format]];
}
@end
