//
//  ImageDownloader.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImageDownloader.h"
#import "ImagesCache.h"


@interface ImageDownloader ()


@end

@implementation ImageDownloader


- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    //    self.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]]; // blocks main queue!

    [self startDownloadingImage];
}

- (void)startDownloadingImage {
    self.image = nil;
    
    if (self.imageURL) {
        
        UIImage *image = [[ImagesCache sharedInstance] getCachedImageForKey:self.imageURL];
        
        if (image) {
            
            NSLog(@"This is cached");
            dispatch_async(dispatch_get_main_queue(), ^{ self.image = image; });
            
        } else {
            
            NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
            
            // another configuration option is backgroundSessionConfiguration (multitasking API required though)
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            
            // create the session without specifying a queue to run completion handler on (thus, not main queue)
            // we also don't specify a delegate (since completion handler is all we need)
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                                // this handler is not executing on the main queue, so we can't do UI directly here
                                                                if (!error) {
                                                                    if ([request.URL isEqual:self.imageURL]) {
                                                                        // UIImage is an exception to the "can't do UI here"
                                                                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                                                                        // but calling "self.image =" is definitely not an exception to that!
                                                                        // so we must dispatch this back to the main queue
                                                                        if (image) {
                                                                            NSLog(@"Caching %@", self.imageURL);
                                                                            [[ImagesCache sharedInstance] cacheImage:image forKey:self.imageURL];
                                                                            dispatch_async(dispatch_get_main_queue(), ^{ self.image = image; });
                                                                        }
                                                                    }
                                                                }
                                                            }];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
            
        }
    }
}


@end
