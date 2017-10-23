//
//  MainCollectionViewCell.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "MainCollectionViewCell.h"
#import "NasaFetcher.h"
#import "Spinner.h"

@interface MainCollectionViewCell()
@property (strong, nonatomic) Spinner *indicator;
@property (strong, nonatomic) ImageDownloader *downloader;
@end

@implementation MainCollectionViewCell


- (void)awakeFromNib {
    [super awakeFromNib];
    
//    _downloader = [[ImageDownloader alloc] init];
    
//    self.contentView.frame = self.bounds;
//    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //    [self makingRoundCorners:4];
   // _title.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];
  //  _imageDescription.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];
    
    [_imageDescription setTextContainerInset:UIEdgeInsetsZero];
    _imageDescription.textContainer.lineFragmentPadding = 0;

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

- (ImageDownloader *)downloader {
    if (!_downloader) _downloader = [[ImageDownloader alloc] init];
    return _downloader;
}

- (Spinner *)indicator {
    if (!_indicator) _indicator = [[Spinner alloc] init];
    return _indicator;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
//    _title.hidden = NO;
//    _imageDescription.hidden = NO;
    _readMoreButton.hidden = NO;
    _buttonHeightConstraint.constant = 15;
    _buttonHeightConstraint.active = YES;
    _imageView.image = nil;
    _likeButton.selected = NO;
}

- (IBAction)readMoreTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [_delegate readMoreButtonTouched:_indexPath];
    }
}

- (IBAction)likedTouched:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        [_delegate likedButtonTouched:_indexPath];
    }
}

- (void)configure:(Photo *)model {
    _title.text = model.title;
    _imageDescription.text = model.someDescription;
    [self.indicator setupWith:_imageView];
    [self.downloader downloadingImageWithURL:[NasaFetcher URLforPhoto:model.nasa_id format:NasaPhotoFormatThumb] completion:^(UIImage *image, NSHTTPURLResponse *httpResponse) {
        if (image) {
        _imageView.image = image;
        [self.indicator stop];
        }
    }];
    
    if (model.isExpanded) {
        _readMoreButton.hidden = YES;
        _buttonHeightConstraint.constant = 0;
    }
    
    if (model.isLiked) {
        _likeButton.selected = YES;
    }
}

@end
