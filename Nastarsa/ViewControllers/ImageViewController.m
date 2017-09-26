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

@interface ImageViewController () <UIScrollViewDelegate>

//@property (nonatomic, strong) UIImage *image;
//@property (nonatomic, strong) ImageDownloader *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) Spinner *indicator;
@end


@implementation ImageViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"we there, scroller bounds size: %f, %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    [self.scrollView addSubview:self.imageView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"scroller bounds size: %f, %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    if (self.image) {
        [self updateMinZoomScaleForSize:self.view.bounds.size];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Properties lazy instantiation

- (Spinner *)indicator {
    if (!_indicator) _indicator = [[Spinner alloc] init];
    return _indicator;
}

- (UIImageView *)imageView {
    NSLog(@"🔵 imageView");
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithImage:self.tempImage];
    }
    return _imageView;
}

// image property does not use an _image instance variable
// instead it just reports/sets the image in the imageView property
// thus we don't need @synthesize even though we implement both setter and getter

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image; // does not change the frame of the UIImageView

    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    NSLog(@"image size: width %f, height %f", self.imageView.image.size.width, self.imageView.image.size.height);
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    [self updateMinZoomScaleForSize:self.view.bounds.size];

    NSLog(@"scrollView contentSize: width %f, height %f", self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    NSLog(@"scrollView bounds: width %f, height %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    
    // next three lines are necessary for zooming
//    _scrollView.minimumZoomScale = 0.2;
//    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;

    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

#pragma mark - UIScrollViewDelegate

// mandatory zooming method in UIScrollViewDelegate protocol

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)updateMinZoomScaleForSize:(CGSize)size {
    NSLog(@"previous min zoom called %f", _scrollView.zoomScale);
    CGFloat widthScale = size.width / self.imageView.bounds.size.width;
    CGFloat heightScale = size.height / self.imageView.bounds.size.height;
    NSLog(@"imageView bounds size: width %f, height %f", self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    _scrollView.minimumZoomScale = MIN(widthScale, heightScale);
    _scrollView.zoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 1.0;
    NSLog(@"update min zoom called %f", _scrollView.zoomScale);
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
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

#pragma mark - Setting the Image from the Image's URL

- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    [self.indicator setupWith:self.view];
    [ImageDownloader downloadingImageWithURL:imageURL completion:^(UIImage *image) {
        [self.indicator stop];
        self.image = image; }];
}

- (IBAction)dismissVC:(id)sender {
    [self dismissViewControllerAnimated:NO
                             completion:nil];
}
@end
