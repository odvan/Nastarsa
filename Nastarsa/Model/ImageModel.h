//
//  ImageModel.h
//  Nastarsa
//
//  Created by Artur Kablak on 07/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageModel : NSObject // this class obsolete, changed by model in CoreData, kept for sentimental reasons

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *someDescription;
@property (strong, nonatomic) NSString *nasa_id;
@property (strong, nonatomic) NSURL *link;
@property (assign, nonatomic) BOOL isExpanded;
@property (assign, nonatomic) BOOL isLiked;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict;

@end
