//
//  Spinner.h
//  Nastarsa
//
//  Created by Artur Kablak on 26/09/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Spinner : NSObject

@property (strong, nonatomic) UIActivityIndicatorView *indicator;

- (void)setupWith:(UIView *)imageView;
- (void)stop;

@end
