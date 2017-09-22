//
//  ImageViewController.h
//  Nastarsa
//
//  Created by Artur Kablak on 20/09/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"
#import "ImageDownloader.h"

@interface ImageViewController : UIViewController

//@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) ImageModel *model;
@property (nonatomic, strong) ImageDownloader *imageView;

@end
