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
    super.readMoreButton.hidden = YES;
    super.buttonHeightConstraint.constant = 0;
    super.likeButton.selected = YES;
}

- (void)configureWith:(Photo *)photo {
    super.title.text = photo.title;
    super.imageDescription.text = photo.someDescription;
    if (photo.image_preview && photo.image_big) {
      super.imageView.image = [UIImage imageWithData:photo.image_preview];;
    }
}

- (IBAction)likedTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [super.delegate likedButtonTouched:super.indexPath];
    }
}


@end
