//
//  MainCollectionViewCell.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "MainCollectionViewCell.h"


@implementation MainCollectionViewCell

- (void)configure:(ImageModel *)model {
    _title.text = model.title;
    _imageDescription.text = model.someDescription;
    _image.imageURL = model.link;
//    [self imageBackgroundLoading: model.link];
}

- (void)imageBackgroundLoading: (NSURL *)link {
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData *imageData = [[NSData alloc] initWithContentsOfURL: link];
        if ( imageData == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            // WARNING: is the cell still using the same data by this point??
            _image.image = [UIImage imageWithData: imageData];
        });
//        [imageData release];
    });
}


@end
