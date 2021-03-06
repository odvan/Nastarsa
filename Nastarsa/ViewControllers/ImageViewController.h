//
//  ImageViewController.h
//  Nastarsa
//
//  Created by Artur Kablak on 20/09/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "Photo+CoreDataProperties.h"


@interface ImageViewController : UIViewController

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *tempImage;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGRect tempImageFrame;

@property (nonatomic, strong) Photo *model;
@property (nonatomic, strong) NSManagedObjectContext *context;

@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (nonatomic, assign) BOOL isNavBarHidden;

@end
