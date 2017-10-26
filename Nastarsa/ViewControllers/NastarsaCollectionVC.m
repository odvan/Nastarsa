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
#import <CoreData/CoreData.h>
#import "Photo.h"
#import "Photo+CoreDataProperties.h"
#import "AppDelegate.h"
#import "NastarsaSingleImageVC.h"

static NSCache * imagesCache;
static NSString * const reuseIdentifier = @"imageCell";
int lastPage = 0;
BOOL isPageRefreshing = NO;
CGSize size; //?
UIRefreshControl *refreshControl;
NSIndexPath *selectedIndexPath;

NSManagedObjectContext *moc;

static CGFloat paddingBetweenCells = 10;
static CGFloat paddingBetweenLines = 10;
static CGFloat inset = 10;

@interface NastarsaCollectionVC () <ExpandedAndButtonsTouchedCellDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) int pageNumber;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;

@end

@implementation NastarsaCollectionVC

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photosData = [[NSMutableArray alloc] init];
    imagesCache = [[NSCache alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.viewContext;
    moc = appDelegate.persistentContainer.newBackgroundContext;
    [Photo printDatabaseStatistics:_context];

//    _nasaCollectionView.allowsMultipleSelection = YES;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //    [self.collectionView registerClass:[MainCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [NasaFetcher pageNumbers:^(int numbers) {
        lastPage = numbers;
        _pageNumber = numbers;
        NSLog(@"got fucking page number!");
        [NasaFetcher fetchPhotos: lastPage
                  withCompletion:^(BOOL success, NSMutableArray *photosData) {
                      if (success) {
                          self.photosData = photosData;
                      } else {
                          // create alert
                      }
                  }];
    }];
    
    [self refreshControlSetup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.nasaCollectionView reloadData];
}

// whenever our Model is set, must update our View
- (void)setPhotosData:(NSMutableArray *)photosData {
    isPageRefreshing = NO;
    [_photosData addObjectsFromArray:photosData];

    [moc performBlock:^{
        [Photo findOrCreatePhotosFrom:_photosData inContext: moc];
        NSError *error = nil;
        if (![moc save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:_context];
        
        //    NSError *error = nil;
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

- (void)refreshControlSetup {
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    self.nasaCollectionView.refreshControl = refreshControl;
}

- (IBAction)refreshControlAction {
    _pageNumber = lastPage;
    [self.nasaCollectionView.refreshControl beginRefreshing];
    [NasaFetcher fetchPhotos: lastPage
              withCompletion:^(BOOL success, NSMutableArray *photosData) {
                  [self.nasaCollectionView.refreshControl endRefreshing];
                  [self.photosData removeAllObjects];
                  if (success) {
                      self.photosData = photosData;
                  } else {
                      // create alert
                  }
              }];
}

- (NSFetchedResultsController<Photo *> *)frc {
    NSLog(@"NSFetchedResultsController triggered");
    
    if (_frc != nil) {
        return _frc;
    }

    NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]];
    // Initialize Fetched Results Controller
    NSFetchedResultsController<Photo *> *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                         managedObjectContext:_context
                                                                                                           sectionNameKeyPath:nil
                                                                                                                    cacheName:nil];
    
    // Configure Fetched Results Controller
    aFetchedResultsController.delegate = self;
    _frc = aFetchedResultsController;
    
    [moc performBlock:^{
        [Photo deletePhotoObjects:moc];
    }];
    
    return _frc;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
        NSInteger index = gesture.view.tag;
        if (index > -1) {
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
            if ([segue.identifier isEqualToString:@"showSelectedCell"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[NastarsaSingleImageVC class]]) {
                    NastarsaSingleImageVC *nSIVC = (NastarsaSingleImageVC *)segue.destinationViewController;
                    nSIVC.photoObjSetup = [self.frc objectAtIndexPath:indexPath];
                    nSIVC.photoObjSetup.image_preview = UIImageJPEGRepresentation(cell.imageView.image, 1.0);
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
    [self performSegueWithIdentifier: @"showImage" sender: gestureRecognizer];
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


#pragma mark - <UIScrollView>

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if (indexPath.row == ([sectionInfo numberOfObjects] - 1)){
        if ((self.pageNumber > 1) && !isPageRefreshing) {
            isPageRefreshing = YES;
            self.pageNumber -= 1;
            NSLog(@"fetching from page: %d", self.pageNumber);
            [self.spinnerWhenNextPageDownload startAnimating];
            [NasaFetcher fetchPhotos: self.pageNumber
                      withCompletion:^(BOOL success, NSMutableArray *photosData) {
                          if (success) {
                              [self.photosData removeAllObjects];
                              self.photosData = photosData;
                          } else {
                              // create alert
                          }
                          [self.spinnerWhenNextPageDownload stopAnimating];
                      }];
        }
    }
}


#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"size for Item called");
    
    CGSize size = self.view.frame.size;
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    
    CGFloat approximateWidth = size.width - 32;
    CGSize sizeForLabel = CGSizeMake(approximateWidth, CGFLOAT_MAX);
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:12.0f] };
    
    CGRect estimatedSizeOfLabel = [photo.someDescription boundingRectWithSize:sizeForLabel
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                        attributes:attributes
                                                                           context:nil];
    
    CGRect estimatedSizeOfTitle = [photo.title boundingRectWithSize:sizeForLabel
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                                 context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 45 - 5;
    
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

//#pragma mark - <UICollectionViewDelegate>

#pragma mark - <ExpandedAndButtonsTouchedCellDelegate>

- (void)readMoreButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photo = [self.frc objectAtIndexPath:indexPath];
    photo.isExpanded = !photo.isExpanded;
    
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    cell.readMoreButton.hidden = YES;
    cell.buttonHeightConstraint.constant = 0;
//    cell.buttonHeightConstraint.active = YES;
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
