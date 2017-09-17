//
//  ImageModel.m
//  Nastarsa
//
//  Created by Artur Kablak on 07/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImageModel.h"
#import "NasaFetcher.h"

@implementation ImageModel


- (instancetype)initWithJSONDictionary:(NSDictionary*)dict {
    
    self = [super init];
    
    if (self) {
        self.title = [dict objectForKey:@"title"];
        self.nasa_id = [dict objectForKey:@"nasa_id"];
        self.someDescription = [dict objectForKey:@"description"];
        self.link = [NasaFetcher URLforPhoto:self.nasa_id
                                      format:NasaPhotoFormatThumb];
    }
    return self;
}

//+ (NSURL *)URLForPhoto:(NSString *)photoLink {
//    photoLink = [NSString stringWithFormat:@"http://images-assets.nasa.gov/image/%@/%@~thumb.jpg", photoLink, photoLink];
//    //photoLink = [photoLink stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLHostAllowedCharacterSet]];
//    return [NSURL URLWithString:photoLink];
//}


@end
