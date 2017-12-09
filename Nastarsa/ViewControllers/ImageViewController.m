//
//  ImageViewController.m
//  Nastarsa
//
//  Created by Artur Kablak on 20/09/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImageViewController.h"
#import "ImageDownloader.h"
#import "NasaFetcher.h"
#import "Spinner.h"
#import "AppDelegate.h"

@interface ImageViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) Spinner *spinner;
@property (strong, nonatomic) ImageDownloader *downloader;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@end

@implementation ImageViewController

UIImageView *animationImage;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self allowRotation:YES];
    
    NSLog(@"we there, scroller bounds size: %f, %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    [self.scrollView addSubview:self.imageView];
    self.imageView.hidden = YES;
    [self settingGestures];
    
    animationImage = [[UIImageView alloc] initWithImage:_tempImage];
    animationImage.frame = _tempImageFrame;
    animationImage.contentMode = UIViewContentModeScaleAspectFill;
    animationImage.clipsToBounds = YES;
    [self.view insertSubview:animationImage atIndex:1];
    
    _likeButton.selected = _model.isLiked;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    NSLog(@"🏈 layout subviews, scroller bounds size): %f, %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    if (self.image) {
        NSLog(@"🔴🔵🔴");
        [self updateMinZoomScaleForSize:self.view.bounds.size];
    }
    
    if ([self.view.subviews containsObject:self.spinner.indicator]) {
        self.spinner.indicator.center = self.view.center;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSLog(@"♥️ animationImage frame %@", NSStringFromCGRect(animationImage.frame));
    
    if (_tempImage) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            CGFloat newImageHeight = animationImage.bounds.size.width / (animationImage.image.size.width / animationImage.image.size.height);
            CGFloat y = self.view.frame.size.height/2 - newImageHeight/2;
            
            if (newImageHeight > self.view.bounds.size.height) {
                CGFloat newImageWidth = (self.view.bounds.size.height/newImageHeight) * animationImage.bounds.size.width;
                CGFloat x = self.view.frame.size.width/2 - newImageWidth/2;
                [animationImage setFrame:CGRectMake(x, 0, newImageWidth, self.view.frame.size.height)];
                self.imageView.frame = animationImage.frame;
            } else {
                [animationImage setFrame:CGRectMake(0, y, self.view.frame.size.width, newImageHeight)];
            }
            NSLog(@"self frame size: %@", NSStringFromCGRect(self.view.frame));
            NSLog(@"♥️♠️ animationImage frame after %@", NSStringFromCGRect(animationImage.frame));
        } completion:^(BOOL finished){
            animationImage.contentMode = UIViewContentModeScaleAspectFit;
            self.imageView.hidden = NO;
            animationImage.hidden = YES;
            [self.spinner setupWith:self.view];
            NSLog(@"imageView frame after %@", NSStringFromCGRect(self.imageView.frame));
            if (self.imageView.image != _tempImage) {
                [self.spinner stop];
            }
        }];
    } else {
        self.imageView.hidden = NO;
    }
}

#pragma mark - Methods and Actions

- (IBAction)tappeLikedButton:(id)sender {
    
    _likeButton.selected = !_likeButton.selected;
    _model.isLiked = !_model.isLiked;
    
    if (_model.isLiked) {
        dispatch_queue_t saveImagesQ = dispatch_queue_create("saving liked images", NULL);
        dispatch_async(saveImagesQ, ^{
            if (_tempImage) {
                _model.image_preview = UIImageJPEGRepresentation(_tempImage, 1.0);
            }
            if (self.image) {
                _model.image_big = UIImageJPEGRepresentation(self.image, 1.0);
            }
            [Photo saveNewLikedPhotoFrom:_model inContext:_context];
        });
    } else {
        [Photo deleteLikedPhotoFrom:_model inContext:_context];
    }
}

- (IBAction)dismissVC:(id)sender {
    
    self.imageView.hidden = YES;
    animationImage.hidden = NO;
    self.likeButton.hidden = YES;
    self.dismissButton.hidden = YES;
    animationImage.frame = self.imageView.frame;
    
    NSLog(@"🏓 🏓 🏓 nav bar visible %s", _isNavBarHidden ? "true" : "false");
    NSLog(@"nav bar height %f", self.navigationController.navigationBar.frame.size.height);
    
    UIInterfaceOrientation screenOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        // if VC rotated we need different animation properties for each case
        switch (screenOrientation) {
            case (UIInterfaceOrientationPortrait):
                NSLog(@"Do something if the orientation is in Portrait: %ld", (long)screenOrientation);
                CGRect frame;
                frame = _tempImageFrame;
                frame.origin.y += (_isNavBarHidden ? 44 : 0);
                animationImage.frame = frame;
                break;
            case (UIInterfaceOrientationLandscapeLeft):
                NSLog(@"Do something if the orientation is in Landscape Left: %ld", (long)screenOrientation);
                
                animationImage.transform = CGAffineTransformMakeRotation(M_PI_2);
                CGFloat xLeft = self.view.frame.size.width - _tempImageFrame.origin.y - _tempImageFrame.size.height - (_isNavBarHidden ? 44 : 0);
                [animationImage setFrame:CGRectMake(xLeft, 0, _tempImageFrame.size.height, self.view.frame.size.height)];
                break;
            case (UIInterfaceOrientationLandscapeRight):
                NSLog(@"Do something if the orientation is in Landscape Right: %ld", (long)screenOrientation);
                
                animationImage.transform = CGAffineTransformMakeRotation(-M_PI_2);
                CGFloat xRight = _tempImageFrame.origin.y + (_isNavBarHidden ? 44 : 0);
                [animationImage setFrame:CGRectMake(xRight, 0, _tempImageFrame.size.height, self.view.frame.size.height)];
                break;
            case (UIInterfaceOrientationPortraitUpsideDown):
                NSLog(@"Do something if the orientation is UpsideDown: %ld", (long)screenOrientation);
                break;
            case (UIInterfaceOrientationUnknown):
                NSLog(@"Default orientation unknown: %ld", (long)screenOrientation);
                break;
        }
       
        animationImage.contentMode = UIViewContentModeScaleAspectFill;
        
    } completion:^(BOOL finished){
        [self allowRotation:NO];
        [self dismissViewControllerAnimated:NO
                                 completion:nil];
    }];
}

- (void)allowRotation:(BOOL)yesOrNo {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.shouldRotate = yesOrNo;
}


#pragma mark - Properties lazy instantiation

- (ImageDownloader *)downloader {
    if (!_downloader) _downloader = [[ImageDownloader alloc] init];
    return _downloader;
}

- (Spinner *)spinner {
    if (!_spinner) _spinner = [[Spinner alloc] init];
    return _spinner;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        if (_tempImage) {
            NSLog(@"🛑🔵🛑 tempImage imageView");
            _imageView = [[UIImageView alloc] initWithImage:self.tempImage];
            NSLog(@"image frame %@", NSStringFromCGRect(_imageView.frame));
        } else {
            _imageView = [[UIImageView alloc] init];
        }
    }
    NSLog(@"🔵 imageView");
    return _imageView;
}

// image property does not use an _image instance variable
// instead it just reports/sets the image in the imageView property
// thus we don't need @synthesize even though we implement both setter and getter

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    NSLog(@"Running on %@ setting image in IVC", [NSThread currentThread]);
    _scrollView.zoomScale = 1.0;
    self.imageView.image = image; // does not change the frame of the UIImageView
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    NSLog(@"🎱 image size: width %f, height %f", self.imageView.image.size.width, self.imageView.image.size.height);
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    [self updateMinZoomScaleForSize:self.view.bounds.size];
    NSLog(@"scrollView contentSize: width %f, height %f", self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    NSLog(@"scrollView bounds: width %f, height %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    _scrollView.delegate = self;

    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

#pragma mark - Setting the Image from the Image's URL

- (void)setImageURL:(NSURL *)imageURL {
    
    _imageURL = imageURL;

    [self.downloader downloadingImageWithURL:imageURL completion:^(UIImage *image, NSHTTPURLResponse *httpResponse) {
        if (image && httpResponse.statusCode != 404) {
            [self.spinner stop];
            self.image = image;
            NSLog(@"⭕️ ⭕️ ⭕️ removing");
        } else {
            NSLog(@"✅ %@", self.model.nasa_id);
            _imageURL = [NasaFetcher URLforPhoto:self.model.nasa_id format:NasaPhotoFormatOriginal];
            NSLog(@"⭕️ %@", _imageURL);
            [self.downloader downloadingImageWithURL:_imageURL completion:^(UIImage *image, NSHTTPURLResponse *httpResponse) {
                if (image && httpResponse.statusCode != 404) {
                    [self.spinner stop];
                    self.image = image;
                } else {
//                    [self.spinner stop];
//                    self.image = self.tempImage;
//                    self.imageView.image = self.tempImage;
                }
                NSLog(@"✝️ ✝️ ✝️ removing");
                [self.spinner stop];
            }];
        }
    }];
}


#pragma mark - <UIScrollViewDelegate>

// mandatory zooming method in UIScrollViewDelegate protocol

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)updateMinZoomScaleForSize:(CGSize)size {
    
    NSLog(@"previous min zoom called %f", _scrollView.zoomScale);
    CGFloat previousZoomScale = _scrollView.zoomScale;
    CGFloat widthScale = size.width / self.imageView.bounds.size.width; // * _scrollView.zoomScale
    CGFloat heightScale = size.height / self.imageView.bounds.size.height;
    NSLog(@"self.view.bounds.size: width %f, height %f", self.view.bounds.size.width, self.view.bounds.size.height);
    NSLog(@"imageView bounds size inside updateZoom: width %f, height %f", self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    
    _scrollView.minimumZoomScale = MIN(widthScale, heightScale);
    _scrollView.zoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 1.0;
    
    if (_scrollView.minimumZoomScale >= 1.0 || previousZoomScale == _scrollView.zoomScale) {
        [self centerScrollViewContents];
    }
    NSLog(@"updated min zoom called %f", _scrollView.zoomScale);
}

- (void)centerScrollViewContents {
    NSLog(@"🔴🔵");
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    self.imageView.frame = contentsFrame;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        self.dismissButton.hidden = NO;
        self.likeButton.hidden = NO;
    } else {
        self.dismissButton.hidden = YES;
        self.likeButton.hidden = YES;
    }
    NSLog(@"🔴🔵 scrollViewDidZoom 🔴🔵");
    [self centerScrollViewContents];
}

#pragma mark - Gestures setup

- (void)settingGestures {
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewSingleTapped:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer:singleTapRecognizer];
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer:doubleTapRecognizer];
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
}

- (void)scrollViewDoubleTapped:(id)sender {
    
    CGPoint pointInView = [sender locationInView:self.imageView];
    
    CGFloat newZoomScale = self.scrollView.zoomScale == self.scrollView.minimumZoomScale ? self.scrollView.maximumZoomScale : self.scrollView.minimumZoomScale;
    
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0);
    CGFloat y = pointInView.y - (h / 2.0);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    [self.scrollView zoomToRect:rectToZoomTo animated:YES];
}

- (void)scrollViewSingleTapped:(id)sender {
    if (self.dismissButton.hidden && self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
        [self scrollViewDoubleTapped:sender];
    } else {
        self.dismissButton.hidden = !self.dismissButton.hidden;
        self.likeButton.hidden = !self.likeButton.hidden;
    }
}

@end
