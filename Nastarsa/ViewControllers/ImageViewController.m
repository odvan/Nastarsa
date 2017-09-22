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
}

#pragma mark - Properties

- (ImageDownloader *)imageView {
    NSLog(@"inside imageView");
    if (!_imageView) {
        NSLog(@"creating imageView");
        _imageView = [[ImageDownloader alloc] init];
        self.imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        CGFloat widthScale = self.view.frame.size.width / self.imageView.bounds.size.width;
        CGFloat heightScale = self.view.frame.size.height / self.imageView.bounds.size.height;
        _scrollView.minimumZoomScale = MIN(widthScale, heightScale);//0.2;
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

//- (UIImage *)image {
//    return self.imageView.image;
//}

//- (void)setModel:(ImageModel *)model {
//    NSLog(@"we there 2");
//    self.imageView.imageURL = [NasaFetcher URLforPhoto:model.nasa_id
//                                                format:NasaPhotoFormatLarge];
//    self.scrollView.zoomScale = 1.0;
//
//    // self.scrollView could be nil on the next line if outlet-setting has not happened yet
//    self.scrollView.contentSize = self.imageView ? self.imageView.image.size : CGSizeZero;
//    NSLog(@"scroll view content size: %f", self.scrollView.contentSize.height);
////    [self.spinner stopAnimating];
//}

- (void)setScrollView:(UIScrollView *)scrollView {
    NSLog(@"inside scrollView");
    _scrollView = scrollView;
    
    // next three lines are necessary for zooming
    self.scrollView.zoomScale = _scrollView.minimumZoomScale;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;
    
    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    self.scrollView.contentSize = self.imageView.image ? self.imageView.image.size : CGSizeZero;
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
