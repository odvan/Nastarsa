//
//  ExampleCell.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ExampleCell.h"

@implementation ExampleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.readMoreButton.hidden = YES;
    self.buttonHeightConstraint.constant = 0;
    self.likeButton.selected = NO;
    self.selectedBackgroundView = nil;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.readMoreButton.hidden = YES;
    self.buttonHeightConstraint.constant = 0;
}

- (void)configureWith:(Photo *)photo {
    self.title.text = photo.title;
    self.imageDescription.text = photo.someDescription;
    self.likeButton.selected = photo.isLiked;
    if (photo.image_preview) { //  && photo.image_big
      self.imageView.image = [UIImage imageWithData:photo.image_preview];
    }
}

- (IBAction)likedTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [self.delegate likedButtonTouched:self.indexPath];
    }
}

- (IBAction)shareTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [self.delegate shareButtonTouched:self.indexPath];
    }
}

@end
