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
    
    [_imageDescription setTextContainerInset:UIEdgeInsetsZero];
    _imageDescription.textContainer.lineFragmentPadding = 0;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRectZero)];
    
    backgroundView.backgroundColor = [UIColor darkGrayColor];
    self.selectedBackgroundView = backgroundView;
}

//- (void)setHighlighted:(BOOL)highlighted {
//    [super setHighlighted:highlighted];
//    NSLog(@"%@", self.contentView.backgroundColor);
//
//    if (self.highlighted) {
//        self.contentView.backgroundColor = [UIColor grayColor];  //|| (self.highlighted && self.selected)
//        NSLog(@"🔲 highlighted");
//    } else {
//        self.contentView.backgroundColor = nil;
//        NSLog(@"⬛️ unhighlighted");
//    }
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

- (void)configure:(Photo *)photoModel {
    _title.text = photoModel.title;
    _imageDescription.text = photoModel.someDescription;
    if (photoModel.image_preview != nil) {
        _imageView.image = [UIImage imageWithData:photoModel.image_preview];
    } else {
        [self.indicator setupWith:_imageView];
        [self.downloader downloadingImageWithURL:[NSURL URLWithString:photoModel.link] completion:^(UIImage *image, NSHTTPURLResponse *httpResponse) {
            if (image) {
                _imageView.image = image;
                [self.indicator stop];
            }
        }];
    }
    if (photoModel.isLiked) {
        _likeButton.selected = YES;
    }
    
    if (photoModel.isExpanded) {
        _readMoreButton.hidden = YES;
        _buttonHeightConstraint.constant = 0;
    }
}

@end
