//
//  ImageDownloader.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageDownloader : UIImageView

@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

@end
