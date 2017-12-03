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
    
    [self makingRoundCorners:4];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _isSelectable = NO;
}

- (UIImageView *)checkView {
    
    if (_checkView != nil) {
        return _checkView;
    }
    
    UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(self.imageView.bounds.size.height/2 - 15, self.imageView.bounds.size.height/2 - 15, 30, 30)];
    view.image = [UIImage imageNamed:@"check_mark_white"];
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.clipsToBounds = YES;
    _checkView = view;
    [self.contentView addSubview:_checkView];
    
    return _checkView;
}

- (void)makingRoundCorners:(CGFloat)cornerRadius {

    self.imageView.layer.cornerRadius = cornerRadius;
    self.imageView.clipsToBounds = YES;
}

- (void)configure:(Photo *)photo {
    
    _imageView.image = [UIImage imageWithData:photo.image_preview];
    _imageTitle.text = photo.title;
}

//- (void)setIsSelectable:(BOOL)isSelectable {
//    _isSelectable = isSelectable;
//    
//    if (_isSelectable) {
////        self.layer.borderWidth = 2.0;
////        self.layer.borderColor = [UIColor whiteColor].CGColor;
//        self.imageView.alpha = 0.4;
//        self.checkView.hidden = NO;
//    } else {
//        self.layer.borderWidth = 0;
//        self.imageView.alpha = 1.0;
//        self.checkView.hidden = YES;
//    }
//}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (self.selected) {
        NSLog(@"SELECTED");
        
        if (_isSelectable) {
            
            NSLog(@"SELECTED & _isSelectable");
            self.imageView.alpha = 0.4;
            self.checkView.hidden = NO;
        }
    } else {
        if (_isSelectable) {
            NSLog(@"DE-SELECTED");
            _isSelectable = NO;
            self.layer.borderWidth = 0;
            self.imageView.alpha = 1.0;
            self.checkView.hidden = YES;
        }
    }
}


@end
