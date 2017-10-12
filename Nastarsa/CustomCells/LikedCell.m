//
//  LikedCell.m
//  Nastarsa
//
//  Created by Artur Kablak on 06/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "LikedCell.h"

@implementation LikedCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
//        self.contentView.frame = self.bounds;
//        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self makingRoundCorners:4];
}

- (void)makingRoundCorners:(CGFloat)cornerRadius {

    self.imageView.layer.cornerRadius = cornerRadius;
    self.imageView.clipsToBounds = YES;
}

- (void)configure:(Photo *)photo {
 
    _imageView.image = [UIImage imageWithData:photo.image_preview];
    _imageTitle.text = photo.title;
}

@end
