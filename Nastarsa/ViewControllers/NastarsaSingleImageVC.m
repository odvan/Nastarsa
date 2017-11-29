//
//  NastarsaSingleImageVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 16/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaSingleImageVC.h"
#import "ExampleCell.h"
#import <CoreData/CoreData.h>
#import "ImageViewController.h"


static NSString * const reuseIdentifier = @"imageCell";
UIImageView *provisionalImageDupl;
UIView *blackViewDupl;
CGRect frameDupl;
BOOL isSeguedFromImageDupl;
__weak ExampleCell *cellForAnimationDupl;

@interface NastarsaSingleImageVC () <ExpandedAndButtonsTouchedCellDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation NastarsaSingleImageVC


#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.newBackgroundContext;
    
//    _singleImageCV.alwaysBounceVertical = YES;
    [self.singleImageCV registerNib:[UINib nibWithNibName:@"ExampleCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [self.singleImageCV reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate setShouldRotate:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    
    if (isSeguedFromImageDupl) {
        [self reverseImageAnimation];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.singleImageCV.collectionViewLayout invalidateLayout];
}


#pragma mark - Properties lazy instantiation

- (void)setPhotoSetup:(Photo *)photoObjSetup {
    if (_photoObjSetup != photoObjSetup) {
        _photoObjSetup = photoObjSetup;
    }
    NSLog(@"setting photoSetup obj: %@", _photoObjSetup);
    [self.singleImageCV reloadData];
}


#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoObjSetup != nil ? 1 : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExampleCell *cell = [self.singleImageCV dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.delegate = self;
    cell.indexPath = indexPath;
    
    [cell configureWith:_photoObjSetup];
    [self settingGesturesWith:cell.imageView];

    return cell;
}


#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize size = self.view.frame.size;
    
    CGFloat approximateWidth = size.width - 32;
    CGSize sizeForLabel = CGSizeMake(approximateWidth, CGFLOAT_MAX);
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:13.0f] };
    
    CGRect estimatedSizeOfLabel = [_photoObjSetup.someDescription boundingRectWithSize:sizeForLabel
                                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                                         attributes:attributes
                                                                            context:nil];
    
    CGRect estimatedSizeOfTitle = [_photoObjSetup.title boundingRectWithSize:sizeForLabel
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                                  context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 44;
    size = CGSizeMake(size.width, heightForItem);
    NSLog(@"setting size: height %f", heightForItem);
    return size;
}


#pragma mark - <ExpandedAndButtonsTouchedCellDelegate>

- (void)likedButtonTouched:(NSIndexPath *)indexPath {
    
    _photoObjSetup.isLiked = !_photoObjSetup.isLiked;
    __weak ExampleCell *cell = (ExampleCell*)[self.singleImageCV cellForItemAtIndexPath:indexPath];
    cell.likeButton.selected = !cell.likeButton.selected;
    
    if (_photoObjSetup.isLiked) {
        _photoObjSetup.image_preview = UIImageJPEGRepresentation(cell.imageView.image, 1.0);
        
        [Photo saveNewLikedPhotoFrom:_photoObjSetup inContext:_context];
    } else {
        [Photo deleteLikedPhotoFrom:_photoObjSetup inContext:_context];
    }
}

- (void)shareButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photo = _photoObjSetup;
    __weak ExampleCell *cell = (ExampleCell*)[self.singleImageCV cellForItemAtIndexPath:indexPath];

    UIImage *imageToShare = cell.imageView.image;
    NSString *textToShare = photo.title;
    NSURL *urlToShare = [NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatLarge];
    
    NSMutableArray *activityItems = [NSMutableArray arrayWithObjects:textToShare, imageToShare, urlToShare, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[
                                                     UIActivityTypePrint,
                                                     UIActivityTypeCopyToPasteboard,
                                                     UIActivityTypeAssignToContact,
                                                     UIActivityTypeSaveToCameraRoll,
                                                     UIActivityTypeAddToReadingList,
                                                     UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}


#pragma mark - Gestures setup

- (void)settingGesturesWith:(UIImageView *)imageView {
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segueToImageVC:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:singleTapRecognizer];
}

//- (void)segueToImageVC:(UITapGestureRecognizer *)gestureRecognizer {
//    [self performSegueWithIdentifier: @"showImageFromLikedVC" sender: gestureRecognizer];
//}

- (void)segueToImageVC:(UITapGestureRecognizer *)gestureRecognizer {
    // there main animation image code
    
    UITapGestureRecognizer *gesture = gestureRecognizer;
    NSInteger index = gesture.view.tag;
    cellForAnimationDupl = (ExampleCell*)[self.singleImageCV cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    blackViewDupl = [[UIView alloc] init];
    blackViewDupl.frame = self.view.frame;
    blackViewDupl.backgroundColor = [UIColor blackColor];
    blackViewDupl.alpha = 0;
    [self.navigationController.view addSubview:blackViewDupl];
    
    provisionalImageDupl = [[UIImageView alloc] init];
    
    frameDupl = CGRectMake(0, 0, cellForAnimationDupl.imageView.frame.size.width, cellForAnimationDupl.imageView.frame.size.height);
    frameDupl = [cellForAnimationDupl.imageView.superview convertRect:cellForAnimationDupl.imageView.frame toView:self.view];
    provisionalImageDupl.frame = frameDupl;
    
    provisionalImageDupl.image = cellForAnimationDupl.imageView.image;
    provisionalImageDupl.contentMode = UIViewContentModeScaleAspectFill;
    provisionalImageDupl.clipsToBounds = YES;
    [self.navigationController.view addSubview:provisionalImageDupl];
    
    NSLog(@" %@", provisionalImageDupl);
    cellForAnimationDupl.imageView.alpha = 0;
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        CGFloat newImageHeight = cellForAnimationDupl.imageView.bounds.size.width / (cellForAnimationDupl.imageView.image.size.width / cellForAnimationDupl.imageView.image.size.height);
        CGFloat y = self.view.frame.size.height/2 - newImageHeight/2;
        blackViewDupl.alpha = 1;
        
        [provisionalImageDupl setFrame:CGRectMake(0, y, self.view.frame.size.width, newImageHeight)];
        
    } completion:^(BOOL finished){
        provisionalImageDupl.contentMode = UIViewContentModeScaleAspectFit;
        [self performSegueWithIdentifier: @"showImageFromLikedVC" sender: gestureRecognizer];
    }];
}

- (void)reverseImageAnimation {
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        provisionalImageDupl.frame = frameDupl;
        provisionalImageDupl.contentMode = UIViewContentModeScaleAspectFill;
        
    } completion:^(BOOL finished){
        cellForAnimationDupl.imageView.alpha = 1;
        [provisionalImageDupl removeFromSuperview];
        [blackViewDupl removeFromSuperview];
        isSeguedFromImageDupl = NO;
        NSLog(@"🏀 content offset: %@", NSStringFromCGPoint(self.singleImageCV.contentOffset));
    }];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
//        NSIndexPath *indexPath = [self.singleImageCV indexPathForCell:sender];
//        if (indexPath) {
//            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"showImageFromLikedVC"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    // yes ... then we know how to prepare for that segue!
//                    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.singleImageCV cellForItemAtIndexPath:indexPath];
                    ImageViewController *iVC = (ImageViewController *)segue.destinationViewController;
                    iVC.context = _context;
                    iVC.model = _photoObjSetup;
                    isSeguedFromImageDupl = YES;
                    if (_photoObjSetup.isLiked && _photoObjSetup.image_big) {
                        iVC.image = [UIImage imageWithData:_photoObjSetup.image_big];
                        iVC.likeButton.selected = YES;
                        NSLog(@"🔴 model liked %s", iVC.model.isLiked ? "true" : "false");
                    } else {
                        UIImageView *imgView = (UIImageView *)gesture.view;
                        iVC.tempImage = imgView.image;
                        iVC.imageURL = [NasaFetcher URLforPhoto:_photoObjSetup.nasa_id format:NasaPhotoFormatLarge];
                        iVC.likeButton.selected = _photoObjSetup.isLiked;
                }
            }
        }
    }
}

@end
