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

@class MainCollectionViewCell;

@protocol ExpandedCellDelegate <NSObject>
@required
- (void)readMoreButtonTouched:(NSIndexPath *)indexPath;
@end

@interface MainCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *imageDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *readMoreButton;
@property (weak, nonatomic) id <ExpandedCellDelegate> delegate;
@property (weak, nonatomic) NSIndexPath *indexPath;

- (IBAction)readMoreTouched:(id)sender;
- (void)configure:(ImageModel *)model;
//- (void)settingLargeImage:(ImageModel *)model;

@end


