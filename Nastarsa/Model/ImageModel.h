//
//  ImageModel.h
//  Nastarsa
//
//  Created by Artur Kablak on 07/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageModel : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *someDescription;
@property (strong, nonatomic) NSString *nasa_id;
@property (strong, nonatomic) NSURL *link;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict;

@end
