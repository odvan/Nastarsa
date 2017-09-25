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
    NSLog(@"we there");
    [self.scrollView addSubview:self.imageView];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateMinZoomScaleForSize:)
     name:@"myNotificationName"
     object:nil];
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

- (ImageDownloader *)imageView {
    NSLog(@"inside imageView");
    if (!_imageView) {
        NSLog(@"creating imageView");
        _imageView = [[ImageDownloader alloc] init];
        self.imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (void)setScrollView:(UIScrollView *)scrollView {
    NSLog(@"inside scrollView");
    _scrollView = scrollView;
    
    // next three lines are necessary for zooming
//    self.scrollView.zoomScale = _scrollView.minimumZoomScale;
//    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;
    
    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    self.scrollView.contentSize = self.imageView.image ? self.imageView.image.size : CGSizeZero;
    NSLog(@"scrollview content size %f", self.scrollView.contentSize.width);
}

- (void)updateMinZoomScaleForSize:(CGSize)size {
    self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
    self.scrollView.contentSize = self.imageView ? self.imageView.image.size : CGSizeZero;
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


#pragma mark - UIScrollViewDelegate
// mandatory zooming method in UIScrollViewDelegate protocol
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (IBAction)dismissVC:(id)sender {
    [self dismissViewControllerAnimated:NO
                             completion:nil];
}
@end
