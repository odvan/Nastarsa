//
//  ImageDownloader.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImageDownloader.h"
#import "ImagesCache.h"
#import "NasaFetcher.h"

@implementation ImageDownloader

+ (void)downloadingImageWithURL:(NSURL *)imageURL completion:(void (^)(UIImage *image))completion {
    
    if (imageURL) {
        UIImage *image = [[ImagesCache sharedInstance] getCachedImageForKey:imageURL];

        if (image) {
            NSLog(@"Picture cached");
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        } else {
            
            NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
            
            // another configuration option is backgroundSessionConfiguration (multitasking API required though)
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            
            // create the session without specifying a queue to run completion handler on (thus, not main queue)
            // we also don't specify a delegate (since completion handler is all we need)
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                                // this handler is not executing on the main queue, so we can't do UI directly here
                                                                NSLog(@"responce: %@", response);
                                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                                NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
                                                                if (!error && httpResponse.statusCode != 404) {
                                                                        // UIImage is an exception to the "can't do UI here"
                                                                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                                                                        // but calling "self.image =" is definitely not an exception to that!
                                                                        // so we must dispatch this back to the main queue
                                                                        if (image) {
                                                                            NSLog(@"Caching %@", imageURL);
                                                                            [[ImagesCache sharedInstance] cacheImage:image forKey:imageURL];
                                                                            
                                                                            if ([request.URL isEqual:imageURL]) {
                                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    completion(image);
                                                                                    NSLog(@"image size: %f, %f", image.size.width, image.size.height);
                                                                                });
                                                                            } else {
                                                                                NSLog(@"⚠️ wrong picture");
                                                                            }
                                                                        }
                                                                }
//                                                                } else {
//                                                                    NSLog(@"trying another link for %@", self.ID);
//                                                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                                                        [_indicator stopAnimating];
//                                                                        [_indicator removeFromSuperview];
//                                                                        if (self.ID) {
//                                                                            self.imageURL = [NasaFetcher URLforPhoto:self.ID format:NasaPhotoFormatOriginal];
//                                                                        }
//                                                                    });
//                                                                }
                                                            }];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        }
    }
}

//- (void)spinner {
//    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    [_indicator setOpaque:YES];
//    _indicator.center = self.center;// it will display in center of image view
//    [self addSubview:_indicator];
//    [_indicator startAnimating];
//}

@end
