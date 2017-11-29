//
//  Spinner.m
//  Nastarsa
//
//  Created by Artur Kablak on 26/09/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "Spinner.h"

@interface Spinner()

@end

@implementation Spinner

- (void)setupWith:(UIImageView *)imageView {
    NSLog(@"indicator called to start");
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [_indicator setOpaque:YES];
    _indicator.center = imageView.center;// it will display in center of image view
    [imageView addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)stop {
    NSLog(@"indicator called to stop");
    [_indicator stopAnimating];
    [_indicator removeFromSuperview];
}
@end
