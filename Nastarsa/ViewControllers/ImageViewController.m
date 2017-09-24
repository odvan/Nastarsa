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

@interface ImageViewController () <UIScrollViewDelegate>

//@property (nonatomic, strong) UIImage *image;
//@property (nonatomic, strong) ImageDownloader *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
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

    [self updateMinZoomScaleForSize:self.view.bounds.size];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Properties

// lazy instantiation
- (UIImageView *)imageView {
    if (!_imageView) _imageView = [[UIImageView alloc] init];
    
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
    
    // had to add these two lines in Shutterbug to fix a bug in "reusing" ImageViewController's MVC
//    [self imageViewSetupConstraints];
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    NSLog(@"image size: width %f, height %f", self.imageView.image.size.width, self.imageView.image.size.height);

    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    [self updateMinZoomScaleForSize:self.view.bounds.size];

    // self.scrollView could be nil on the next line if outlet-setting has not happened yet
    NSLog(@"scrollView contentSize: width %f, height %f", self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    NSLog(@"scrollView bounds: width %f, height %f", self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);

//    [self.spinner stopAnimating];
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
    CGFloat widthScale = size.width / self.imageView.bounds.size.width;
    CGFloat heightScale = size.height / self.imageView.bounds.size.height;
    NSLog(@"imageView bounds size: width %f, height %f", self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    _scrollView.minimumZoomScale = MIN(widthScale, heightScale);
    _scrollView.zoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 1.0;

}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect innerFrame = _imageView.frame;
    CGRect scrollerBounds = scrollView.bounds;
    
    if ( ( innerFrame.size.width < scrollerBounds.size.width ) || ( innerFrame.size.height < scrollerBounds.size.height ) )
    {
        CGFloat tempx = _imageView.center.x - ( scrollerBounds.size.width / 2 );
        CGFloat tempy = _imageView.center.y - ( scrollerBounds.size.height / 2 );
        CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
        
        scrollView.contentOffset = myScrollViewOffset;
        
    }
    
    UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
    if ( scrollerBounds.size.width > innerFrame.size.width )
    {
        anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
        anEdgeInset.right = -anEdgeInset.left;  // I don't know why this needs to be negative, but that's what works
    }
    if ( scrollerBounds.size.height > innerFrame.size.height )
    {
        anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
        anEdgeInset.bottom = -anEdgeInset.top;  // I don't know why this needs to be negative, but that's what works
    }
    scrollView.contentInset = anEdgeInset;
}

//- (void)updateConstraintsForSize:(CGSize)size {
//    
//    CGFloat yOffset = MAX(0, (size.height - self.imageView.frame.size.height) / 2);
//    [self.imageView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:yOffset];
//    [self.imageView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:yOffset];
//    
//    CGFloat xOffset = MAX(0, (size.width - self.imageView.frame.size.width) / 2);
//    [self.imageView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:xOffset];
//    [self.imageView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:xOffset];
//    
//    [self.view layoutIfNeeded];
//}
//
//- (void)imageViewSetupConstraints {
//    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
////    [self.imageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
////    [self.imageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
//    [self.imageView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor].active = YES;
//    [self.imageView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor].active = YES;
//    [self.imageView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
//    [self.imageView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;
//}

#pragma mark - Setting the Image from the Image's URL

- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;

    [ImageDownloader DownloadingImageWithURL:imageURL completion:^(UIImage *image) {
    self.image = image; }];
}

- (IBAction)dismissVC:(id)sender {
    [self dismissViewControllerAnimated:NO
                             completion:nil];
}
@end
