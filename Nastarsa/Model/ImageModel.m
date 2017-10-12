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
        self.isExpanded = NO;
        self.isLiked = NO;
    }
    return self;
}

@end
