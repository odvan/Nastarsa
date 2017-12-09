//
//  MainCollectionViewCell.h
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageDownloader.h"
#import "Photo.h"
#import "Photo+CoreDataProperties.h"

@class MainCollectionViewCell;

@protocol ExpandedAndButtonsTouchedCellDelegate <NSObject>
@required
- (void)likedButtonTouched:(NSIndexPath *)indexPath;
- (void)shareButtonTouched:(NSIndexPath *)indexPath;
@optional
- (void)readMoreButtonTouched:(NSIndexPath *)indexPath;
@end


@interface MainCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *title;
@property (weak, nonatomic) IBOutlet UITextView *imageDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonHeightConstraint;

@property (weak, nonatomic) id <ExpandedAndButtonsTouchedCellDelegate> delegate;
@property (weak, nonatomic) NSIndexPath *indexPath;

@property (weak, nonatomic) IBOutlet UIButton *readMoreButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

- (IBAction)readMoreTouched:(id)sender;
- (void)configure:(Photo *)photoModel;
- (IBAction)shareTouched:(id)sender;

@end


