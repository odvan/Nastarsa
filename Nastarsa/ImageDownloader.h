//
//  ImageDownloader.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageDownloader: NSObject

@property (strong, nonatomic) NSURL *imageURL;

- (void)downloadingImageWithURL:(NSURL *)imageURL completion:(void (^)(UIImage *image, NSHTTPURLResponse *httpResponse))completion;

@end
