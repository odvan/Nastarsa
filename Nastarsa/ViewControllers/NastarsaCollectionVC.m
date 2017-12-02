//
//  NastarsaCollectionVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaCollectionVC.h"
#import "MainCollectionViewCell.h"
#import "NasaFetcher.h"
#import "ImageViewController.h"
#import "AppDelegate.h"
#import "ImagesCache.h"

//#import "NastarsaSingleImageVC.h"
#import "SingleCellVC.h"
#import "SearchHeader.h"

static NSCache * imagesCache;
static NSString * const reuseIdentifier = @"imageCell";
static NSString * const searchHeaderIdentifier = @"searchHeader";
__weak MainCollectionViewCell *cellForAnimation;

int lastPage = 0;
BOOL isPageRefreshing = NO;
BOOL isSeguedFromImage;

UIRefreshControl *refreshControl;
NSIndexPath *selectedIndexPath;
UIImageView *provisionalImage;
UIView *blackView;
CGRect frame;
UILabel *noData;
NSManagedObjectContext *moc;

static CGFloat paddingBetweenCells = 10;
static CGFloat paddingBetweenLines = 10;
static CGFloat inset = 10;

@interface NastarsaCollectionVC () <ExpandedAndButtonsTouchedCellDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate>

@property (nonatomic, assign) int pageNumber;
//@property (nonatomic, strong) NSManagedObjectContext *context;
//@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL searchBarHasText;

@end

@implementation NastarsaCollectionVC

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    _photosData = [[NSMutableArray alloc] init];
    imagesCache = [[NSCache alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.viewContext;
    _context.automaticallyMergesChangesFromParent = YES;
    
    moc = appDelegate.persistentContainer.newBackgroundContext;
    
    [self settingStatusBackgroundColor];
    
    [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
        if (success) {
            lastPage = numbers;
            _pageNumber = numbers;
            NSLog(@"got fucking page number!");
            [NasaFetcher fetchPhotos:_searchText pageNumber:lastPage withCompletion:^(BOOL success, NSMutableArray *photosData) {
                if (success) {
                    self.photosData = photosData;
                } else {
                    [self showAlertWith:@"Error" message:@"Can't parse JSON."];
                }
            }];
        } else {
            [self showAlertWith:@"Error" message:@"Can't download initial data."];
        }
    }];
    
    [self refreshControlSetup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [self.nasaCollectionView reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate setShouldRotate:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController.navigationBar.isHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
    if (isSeguedFromImage) {
        [self reverseImageAnimation];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self.nasaCollectionView.collectionViewLayout invalidateLayout];
}

- (void)settingStatusBackgroundColor {
    UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    [statusBarBackgroundView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:statusBarBackgroundView];
}

#pragma mark - Properties lazy instantiation
// whenever our Model is set, must update our View
- (void)setPhotosData:(NSMutableArray *)photosData {
    isPageRefreshing = NO;
    [_photosData addObjectsFromArray:photosData];
    
    [moc performBlock:^{
        [Photo findOrCreatePhotosFrom:_photosData inContext:moc withPage:_pageNumber];
        NSError *error = nil;
        if (![moc save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:_context];
        
        NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
        // Add Sort Descriptors
        if (_searchText == nil) {
            [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tempID" ascending:NO]]];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isFetchable == YES"]];
        } else {
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isFetchable == YES"]];
            [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tempID" ascending:YES]]];
        }
        // Initialize Fetched Results Controller
        NSFetchedResultsController<Photo *> *newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                               managedObjectContext:_context
                                                                                                                 sectionNameKeyPath:nil
                                                                                                                          cacheName:nil];
        _frc = newFetchedResultsController;
        
        [_frc performFetch:&error];
        if (error) {
            NSLog(@"Unable to perform fetch.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.nasaCollectionView reloadData];
        });
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)refreshControlSetup {
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    self.nasaCollectionView.refreshControl = refreshControl;
}

- (IBAction)refreshControlAction {
    [self.nasaCollectionView.refreshControl beginRefreshing];
    if (_searchBarHasText) {
        _pageNumber = 1;
    } else {
        if (lastPage == 0) {
            [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
                if (success) {
                    lastPage = numbers;
                    _pageNumber = numbers;
                    NSLog(@"got fucking page number!");
                } else {
                    [self showAlertWith:@"Error" message:@"Can't download initial data."];
                }
            }];
        } else {
            _pageNumber = lastPage;
        }
    }
    [NasaFetcher fetchPhotos:_searchText pageNumber:_pageNumber withCompletion:^(BOOL success, NSMutableArray *photosData) {
        [self.nasaCollectionView.refreshControl endRefreshing];
        [self.photosData removeAllObjects];
        if (success) {
            self.photosData = photosData;
        } else {
            [self showAlertWith:@"Error" message:@"Can't download initial data."];
        }
    }];
}

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
    
    [Photo deletePhotoObjects:moc];
    NSLog(@"🔷");
    return _frc;
}

- (void)setSearchText:(NSString *)text {
    NSLog(@"✅ setting search text: %@", text);
    if (_searchText != text) {
        _searchText = text;
        
        blackView = [[UIView alloc] init];
        blackView.frame = self.view.frame;
        blackView.backgroundColor = [UIColor blackColor];
        blackView.alpha = 0.75;
        [self.view insertSubview:blackView atIndex:1];
        
        [self.spinnerWhenNextPageDownload startAnimating];
        [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
            if (success) {
                lastPage = numbers;
                if (_searchText == nil) {
                    _pageNumber = lastPage;
                } else {
                    _pageNumber = 1;
                }
                NSLog(@"got fucking page number!");
                [NasaFetcher fetchPhotos:_searchText pageNumber:_pageNumber withCompletion:^(BOOL success, NSMutableArray *photosData) {

                    [self.spinnerWhenNextPageDownload stopAnimating];
                    if (success) {
                        self.photosData = photosData;
                    } else {
                        [self showAlertWith:@"Error" message:@"Can't parse JSON."];
                    }
                }];
            } else {
                [self.spinnerWhenNextPageDownload stopAnimating];
                [self showAlertWith:@"Error" message:@"Can't download initial data."];
            }
            [blackView removeFromSuperview];
        }];
    }
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
//                    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
                    ImageViewController *iVC = (ImageViewController *)segue.destinationViewController;
                    Photo *photoObject = [self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                    iVC.context = moc;
                    iVC.model = photoObject;
                    isSeguedFromImage = YES;
                    if (photoObject.isLiked && photoObject.image_big) {
                        iVC.image = [UIImage imageWithData:photoObject.image_big];
                        iVC.likeButton.selected = YES;
                        NSLog(@"🔴 model liked %s", iVC.model.isLiked ? "true" : "false");
                    } else {
                        UIImageView *imgView = (UIImageView *)gesture.view;
                        iVC.tempImage = imgView.image;
                        iVC.imageURL = [NasaFetcher URLforPhoto:photoObject.nasa_id format:NasaPhotoFormatLarge];
                        iVC.likeButton.selected = photoObject.isLiked;
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
            if ([segue.identifier isEqualToString:@"showSomeSingleCell"]) {  //@"showSelectedCell"]) {
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


#pragma mark - Gestures setup

- (void)settingGesturesWith:(UIImageView *)imageView {
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segueToImageVC:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:singleTapRecognizer];
}

- (void)segueToImageVC:(UITapGestureRecognizer *)gestureRecognizer {
    
    // there main animation image code
    UITapGestureRecognizer *gesture = gestureRecognizer;
    NSInteger index = gesture.view.tag;
    cellForAnimation = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    blackView = [[UIView alloc] init];
    blackView.frame = self.view.frame;
    blackView.backgroundColor = [UIColor blackColor];
    blackView.alpha = 0;
    [self.navigationController.view addSubview:blackView];
    
    provisionalImage = [[UIImageView alloc] init];
    
    frame = CGRectMake(0, 0, cellForAnimation.imageView.frame.size.width, cellForAnimation.imageView.frame.size.height);
    frame = [cellForAnimation.imageView.superview convertRect:cellForAnimation.imageView.frame toView:self.view];
    provisionalImage.frame = frame;

    provisionalImage.image = cellForAnimation.imageView.image;
    provisionalImage.contentMode = UIViewContentModeScaleAspectFill;
    provisionalImage.clipsToBounds = YES;
    [self.navigationController.view addSubview:provisionalImage];
    
    NSLog(@" %@", provisionalImage);
    cellForAnimation.imageView.alpha = 0;

    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        CGFloat newImageHeight = cellForAnimation.imageView.bounds.size.width / (cellForAnimation.imageView.image.size.width / cellForAnimation.imageView.image.size.height);
        CGFloat y = self.view.frame.size.height/2 - newImageHeight/2;
        blackView.alpha = 1;
        
        [provisionalImage setFrame:CGRectMake(0, y, self.view.frame.size.width, newImageHeight)];
        
    } completion:^(BOOL finished){
        provisionalImage.contentMode = UIViewContentModeScaleAspectFit;
        [self performSegueWithIdentifier: @"showImage" sender: gestureRecognizer];
    }];
}

- (void)reverseImageAnimation {
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        provisionalImage.frame = frame;
        provisionalImage.contentMode = UIViewContentModeScaleAspectFill;
        blackView.alpha = 0;
        
    } completion:^(BOOL finished){
        cellForAnimation.imageView.alpha = 1;
        [provisionalImage removeFromSuperview];
        [blackView removeFromSuperview];
        isSeguedFromImage = NO;
        NSLog(@"🏀 content offset: %@", NSStringFromCGPoint(self.nasaCollectionView.contentOffset));
    }];
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        SearchHeader *searchHeader = [self.nasaCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:searchHeaderIdentifier forIndexPath:indexPath];
        
        return searchHeader;
    }
    return [UICollectionReusableView new];
}

#pragma mark - <UIScrollView>

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (velocity.y > 0) {
        NSLog(@"🔻 velocity: %f", velocity.y);
        //Code will work without the animation block.I am using animation block incase if you want to set any delay to it.
//        [UIView animateWithDuration:1 delay:0 options:0 animations:^{
            [self.navigationController setNavigationBarHidden:YES animated:YES];
//        } completion:^(BOOL finished) {
//            nil;
//        }];
        
    } else if (velocity.y < 0){
        NSLog(@"🔺🔺🔺 velocity: %f", velocity.y);
//        [UIView animateWithDuration:1 delay:0 options:0 animations:^{
            [self.navigationController setNavigationBarHidden:NO animated:YES];
//        } completion:^(BOOL finished) {
//            nil;
//        }];
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if (indexPath.row == ([sectionInfo numberOfObjects] - 1)) {
        if (_searchBarHasText) {
            if ((self.pageNumber < lastPage) && !isPageRefreshing) {
                isPageRefreshing = YES;
                self.pageNumber += 1;
            } else {
                return;
            }
        } else {
            if ((self.pageNumber > 1) && !isPageRefreshing) {
                isPageRefreshing = YES;
                self.pageNumber -= 1;
            } else {
                return;
            }
        }
        
        if (self.pageNumber <= lastPage) {
            NSLog(@"fetching from page: %d", self.pageNumber);
            [self.spinnerWhenNextPageDownload startAnimating];
            
            [NasaFetcher fetchPhotos:_searchText pageNumber:self.pageNumber withCompletion:^(BOOL success, NSMutableArray *photosData) {
                if (success) {
                    [self.photosData removeAllObjects];
                    self.photosData = photosData;
                } else {
                    [self showAlertWith:@"Error" message:@"Can't download initial data."];
                }
                [self.spinnerWhenNextPageDownload stopAnimating];
            }];
        }
    }
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
        
        [Photo saveNewLikedPhotoFrom:photo inContext:moc];
    } else {
        [Photo deleteLikedPhotoFrom:photo inContext:moc];
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
//                                                     UIActivityTypePrint,
//                                                     UIActivityTypeCopyToPasteboard,
//                                                     UIActivityTypeAssignToContact,
//                                                     UIActivityTypeSaveToCameraRoll,
//                                                     UIActivityTypeAddToReadingList,
//                                                     UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - <SearchBar Methods>

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [Photo deletePhotoObjects:_context];
    [self.photosData removeAllObjects];
    [searchBar resignFirstResponder];
      //    [Photo printDatabaseStatistics:_context];
    
    if (searchBar.text && [searchBar.text length]) {
        _searchBarHasText = YES;
        NSLog(@"✅✅✅ searching... %@", searchBar.text);
        [self.nasaCollectionView reloadData];

        self.searchText = [SearchHeader multipleWordsSearchCheckAndProperUsage:(searchBar.text)];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
    if (_searchBarHasText) {
        NSLog(@"🔵🔴⚫️ and _searchBarHasText: %s", _searchBarHasText ? "true" : "false");

        [Photo deletePhotoObjects:_context];
        [self.photosData removeAllObjects];
        searchBar.text = nil;
        self.searchText = nil;
    }
    _searchBarHasText = NO;
}

// MARK: - Displaying alert message when error occured

- (void)showAlertWith:(NSString *)title message:(NSString *)message {
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Button
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    [self dismissViewControllerAnimated:YES
                                                             completion:nil];
                                }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
