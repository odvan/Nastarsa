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

- (void)downloadingImageWithURL:(NSURL *)imageURL completion:(void (^)(UIImage *image, NSHTTPURLResponse *httpResponse))completion {
    
    _imageURL = imageURL;
    
    if (imageURL) {
        UIImage *image = [[ImagesCache sharedInstance] getCachedImageForKey:imageURL];

        if (image) {
            NSLog(@"Picture cached");
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image, nil);
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
                                                                if (!error && httpResponse.statusCode != 404) {
                                                                    // UIImage is an exception to the "can't do UI here"
                                                                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                                                                    // but calling "self.image =" is definitely not an exception to that!
                                                                    // so we must dispatch this back to the main queue
                                                                    if ([request.URL isEqual:_imageURL]) {
                                                                        if (image) {
                                                                            NSLog(@"Caching %@", imageURL);
                                                                            [[ImagesCache sharedInstance] cacheImage:image forKey:imageURL];
                                                                            
                                                                                completion(image, nil);
                                                                                NSLog(@"image size: %f, %f", image.size.width, image.size.height);
                                                                            
                                                                        } else {
                                                                            NSLog(@"⚠️ wrong picture");
                                                                        }
                                                                    }
                                                                } else {
                                                                    NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        completion(nil, httpResponse);});
                                                                }
                                                            }];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        }
    }
}

@end
