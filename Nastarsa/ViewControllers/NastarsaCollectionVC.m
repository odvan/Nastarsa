//
//  NastarsaCollectionVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaCollectionVC.h"
#import "ImageViewController.h"
#import "AppDelegate.h"
#import "ImagesCache.h"
#import "SingleCellVC.h"
#import "NasaFetcher.h"

static NSCache * imagesCache;
static NSString * const reuseIdentifier = @"imageCell";
static CGFloat paddingBetweenCells = 10;
static CGFloat paddingBetweenLines = 10;
static CGFloat inset = 10;

@interface NastarsaCollectionVC () //?<UISearchBarDelegate>

@end

@implementation NastarsaCollectionVC

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    imagesCache = [[NSCache alloc] init];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _backgroundContext = appDelegate.persistentContainer.newBackgroundContext;
    _context = appDelegate.persistentContainer.viewContext;
    _context.automaticallyMergesChangesFromParent = YES;
    
    [appDelegate setShouldRotate:NO];
    
    [self settingStatusBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [self.nasaCollectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController.navigationBar.isHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)settingStatusBackgroundColor {
    UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    [statusBarBackgroundView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:statusBarBackgroundView];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark - Properties lazy instantiation

- (NSFetchedResultsController<Photo *> *)frc {
    NSLog(@"NSFetchedResultsController triggered");
    
    if (_frc != nil) {
        NSLog(@"❇️");
        return _frc;
    }

    NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tempID" ascending:NO]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isFetchable == YES"]];
    // Initialize Fetched Results Controller
    NSFetchedResultsController<Photo *> *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                         managedObjectContext:_context
                                                                                                           sectionNameKeyPath:nil
                                                                                                                    cacheName:nil];
    
    // Configure Fetched Results Controller
    aFetchedResultsController.delegate = self;
    _frc = aFetchedResultsController;
    
    [Photo deletePhotoObjects:_backgroundContext];
    NSLog(@"🔷");
    return _frc;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
        NSInteger index = gesture.view.tag;
        if (index >= 0) {
            // found it ... are we doing the show Image segue?
            if ([segue.identifier isEqualToString:@"showImage"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    // yes ... then we know how to prepare for that segue!
                    ImageViewController *iVC = (ImageViewController *)[segue destinationViewController];
                    Photo *photoObject = [_frc objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                    iVC.context = _backgroundContext;
                    iVC.model = photoObject;
                    UIImageView *imgView = (UIImageView *)gesture.view;
                    //setting temp frame for animation
                    CGRect tempFrame = CGRectMake(0, 0, imgView.frame.size.width, imgView.frame.size.height);
                    tempFrame = [imgView.superview convertRect:imgView.frame toView:self.view];
                    iVC.tempImageFrame = tempFrame;
                    iVC.tempImage = imgView.image;
                    iVC.isNavBarHidden = self.navigationController.isNavigationBarHidden;
                    
                    if (photoObject.isLiked && photoObject.image_big) {
                        iVC.image = [UIImage imageWithData:photoObject.image_big];

                    } else {
                        iVC.imageURL = [NasaFetcher URLforPhoto:photoObject.nasa_id format:NasaPhotoFormatLarge];

                    }
                }
            }
        }
    }
    
    if ([sender isKindOfClass:[MainCollectionViewCell class]]) {
        NSIndexPath *indexPath = [self.nasaCollectionView indexPathForCell:sender];
        __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
        if (indexPath) {
            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"showSingleCell"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[SingleCellVC class]]) {
                    SingleCellVC *nSIVC = (SingleCellVC *)segue.destinationViewController;
                    nSIVC.photoObjSetupDouble = [self.frc objectAtIndexPath:indexPath];
                    nSIVC.photoObjSetupDouble.image_preview = UIImageJPEGRepresentation(cell.imageView.image, 1.0);
                }
            }
        }
    }
}


#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MainCollectionViewCell *cell = [self.nasaCollectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.delegate = self;
    cell.indexPath = indexPath;

    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    if (photo) {
        NSLog(@"cell setup called");
        [cell configure:photo];
    }
    NSLog(@"cell for Item called");
    [self settingGesturesWith:cell.imageView];
    cell.imageView.tag = indexPath.row;
    
    return cell;
}


#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"size for Item called");
    
    CGSize size = self.view.frame.size;
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    
    CGFloat approximateWidth = size.width - 32;
    CGSize sizeForLabel = CGSizeMake(approximateWidth, CGFLOAT_MAX);
    
    CGRect estimatedSizeOfLabel = [photo.someDescription boundingRectWithSize:sizeForLabel
                                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                                   attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:13.0f] }
                                                                      context:nil];
    
    CGRect estimatedSizeOfTitle = [photo.title boundingRectWithSize:sizeForLabel
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                            context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 44;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // Device is iPad
        size = CGSizeMake((size.width - paddingBetweenCells)/3 - inset, (size.width - paddingBetweenLines)/3 - inset + 125 + 45);
    } else {
        if (photo.isExpanded == YES && heightForItem > size.width + 125 + 45) {
            NSLog(@"somehow it's triggered 😀");
            size = CGSizeMake(size.width, heightForItem);
        } else {
            if (heightForItem < size.width + 125 + 45) {
                NSLog(@"heightForItem < size.width + 125");
                photo.isExpanded = YES;
            }
            size = CGSizeMake(size.width, size.width + 125 + 45);
        }
    }
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // Device is iPad
        return UIEdgeInsetsMake(inset, inset, inset, inset);
    } else {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return paddingBetweenCells;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return paddingBetweenLines;
}


#pragma mark - Gestures setup

- (void)settingGesturesWith:(UIImageView *)imageView {
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segueToImageVC:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:singleTapRecognizer];
}

- (void)segueToImageVC:(UITapGestureRecognizer *)gestureRecognizer {
    [self performSegueWithIdentifier: @"showImage" sender: gestureRecognizer];
}


#pragma mark - <ExpandedAndButtonsTouchedCellDelegate>

- (void)readMoreButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    photo.isExpanded = !photo.isExpanded;
    
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    cell.readMoreButton.hidden = YES;
    cell.buttonHeightConstraint.constant = 0;

    NSArray *indexes = [[NSArray alloc] init];
    [indexes arrayByAddingObject:indexPath];
    [UIView animateWithDuration:0.8
                          delay:0.0
         usingSpringWithDamping:0.9
          initialSpringVelocity:0.9
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.nasaCollectionView reloadItemsAtIndexPaths:indexes];
                     }
                     completion:^(BOOL finished) {
                         nil; }];
}

- (void)likedButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    photo.isLiked = !photo.isLiked;
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    cell.likeButton.selected = !cell.likeButton.selected;
    
    if (photo.isLiked) {
        photo.image_preview = UIImageJPEGRepresentation(cell.imageView.image, 1.0);
        
        [Photo saveNewLikedPhotoFrom:photo inContext:_backgroundContext];
    } else {
        [Photo deleteLikedPhotoFrom:photo inContext:_backgroundContext];
    }
}

- (void)shareButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];

    UIImage *imageToShare;
    
    if (photo.image_big) {
        imageToShare = [UIImage imageWithData:(photo.image_big)];
    } else if ([[ImagesCache sharedInstance] getCachedImageForKey:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatOriginal]]) {
        imageToShare = [[ImagesCache sharedInstance] getCachedImageForKey:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatOriginal]];
    } else if ([[ImagesCache sharedInstance] getCachedImageForKey:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatLarge]]) {
        imageToShare = [[ImagesCache sharedInstance] getCachedImageForKey:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatLarge]];
    } else {
       imageToShare = cell.imageView.image;
    }
    NSString *textToShare = photo.title;
    NSURL *urlToShare = [NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatLarge];
    
    NSMutableArray *activityItems = [NSMutableArray arrayWithObjects:textToShare, imageToShare, urlToShare, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
//    activityViewController.excludedActivityTypes = @[
//                                                     UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}


@end
