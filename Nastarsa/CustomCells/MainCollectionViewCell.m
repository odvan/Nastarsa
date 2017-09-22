//
//  MainCollectionViewCell.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "MainCollectionViewCell.h"
#import "NasaFetcher.h"


@implementation MainCollectionViewCell


- (void)awakeFromNib {
    [super awakeFromNib];
    
//    self.contentView.frame = self.bounds;
//    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //    [self makingRoundCorners:4];
   // _title.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];
  //  _imageDescription.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];

}

//- (void)makingRoundCorners:(CGFloat)cornerRadius {
//    
//    _title.layer.cornerRadius = cornerRadius;
//    _title.clipsToBounds = YES;
//    _image.layer.cornerRadius = cornerRadius;
//    _image.clipsToBounds = YES;
//    _imageDescription.layer.cornerRadius = cornerRadius;
//    _imageDescription.clipsToBounds = YES;
//
//}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    NSLog(@"prepare %@", _title.text);
    
    _title.hidden = NO;
    _imageDescription.hidden = NO;
    _readMoreButton.hidden = NO;
    _buttonHeightConstraint.constant = 15;
    _buttonHeightConstraint.active = YES;
}

- (IBAction)readMoreTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [_delegate readMoreButtonTouched:_indexPath];
    }
}

- (void)configure:(ImageModel *)model {
    _title.text = model.title;
    _imageDescription.text = model.someDescription;
    _image.imageURL = model.link;
    
    if (model.isExpanded) {
        _readMoreButton.hidden = YES;
        _buttonHeightConstraint.constant = 0;
    }
}

- (void)settingLargeImage:(ImageModel *)model {
    _image.imageURL = [NasaFetcher URLforPhoto:model.nasa_id
                                        format:NasaPhotoFormatLarge];
}

@end
