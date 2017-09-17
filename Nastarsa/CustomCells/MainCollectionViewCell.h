//
//  MainCollectionViewCell.h
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"
#import "ImageDownloader.h"

@interface MainCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet ImageDownloader *image;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *imageDescription;
@property (weak, nonatomic) IBOutlet UIView *paddingView;

- (void)configure:(ImageModel *)model;
- (void)settingLargeImage:(ImageModel *)model;

@end
