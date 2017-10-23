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
@property (nonatomic, strong) NSBlockOperation *blockOperation;
@property (nonatomic, assign) BOOL shouldReloadCollectionView;

@end

@implementation NastarsaCollectionVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photos = [[NSMutableArray alloc] init];
    imagesCache = [[NSCache alloc] init];
    
//    _nasaCollectionView.allowsMultipleSelection = YES;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //    [self.collectionView registerClass:[MainCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [NasaFetcher pageNumbers:^(int numbers) {
        lastPage = numbers;
        _pageNumber = numbers;
        NSLog(@"fuck it");
        [NasaFetcher fetchPhotos:lastPage completion:^(BOOL success){
            if (success) {
                [self frc];
            }
        }];
    }];
    
    [self refreshControlSetup];
//    
//    [[NSNotificationCenter defaultCenter]
//     addObserver:self
//     selector:@selector(someReactionFrom:)
//     name:NSManagedObjectContextObjectsDidChangeNotification
//     object:nil];
    
//    [self frc];

}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    NSError *error = nil;
//    [_frc performFetch:&error];
//}

- (NSFetchedResultsController<Photo *> *)frc {
    NSLog(@"NSFetchedResultsController triggered");
    
    if (_frc != nil) {
        return _frc;
    }
    self.context = [CoreDataStack mainUIManagedObjectContext];
    NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    // Initialize Fetched Results Controller
    NSFetchedResultsController<Photo *> *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                         managedObjectContext:self.context
                                                                                                           sectionNameKeyPath:nil
                                                                                                                    cacheName:nil];
    
    // Configure Fetched Results Controller
    aFetchedResultsController.delegate = self;
    // Perform Fetch
    NSError *error = nil;
    [aFetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    _frc = aFetchedResultsController;
    return _frc;
}

// whenever our Model is set, must update our View

//- (void)setPhotos:(NSMutableArray *)photos {
//    isPageRefreshing = NO;
//    [_photos addObjectsFromArray:photos];
//    [self checkingLoadedPhotoWasLiked];
//    [self.nasaCollectionView reloadData];
//}

- (void)refreshControlSetup {
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    self.nasaCollectionView.refreshControl = refreshControl;
}

- (IBAction)refreshControlAction {
    _pageNumber = lastPage;
    [self.nasaCollectionView.refreshControl beginRefreshing];
    [NasaFetcher fetchPhotos:lastPage completion:^(BOOL success){
        if (success) {
            [self frc];
        }
    }];
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
                    if (_photos[index].isLiked) {
                        if (moc) {
                            [moc performBlock:^{
                                NSLog(@"Running on %@ thread (preparing for segue)", [NSThread currentThread]);
                                NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
                                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", _photos[index].nasa_id]];
                                NSError *error = nil;
                                NSArray <Photo *> *likedPhotoArray = [moc executeFetchRequest:fetchRequest error:&error];
                                NSUInteger count = [moc countForFetchRequest:fetchRequest error:&error];
                                NSLog(@"%lu liked images", (unsigned long) count);
                                if (count > 0) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        iVC.image = [UIImage imageWithData:likedPhotoArray[0].image_big];
                                        iVC.likeButton.selected = YES;
                                        NSLog(@"🔴 model liked %s", iVC.model.isLiked ? "true" : "false");
                                    });
                                }
                            }];
                        }
                    } else {
                        UIImageView *imgView = (UIImageView *)gesture.view;
                        iVC.tempImage = imgView.image;
                        iVC.imageURL = [NasaFetcher URLforPhoto:_photos[index].nasa_id format:NasaPhotoFormatLarge];
                        iVC.model = _photos[index];
                        iVC.likeButton.selected = _photos[index].isLiked;
                        NSLog(@"🔵 🔵 🔵 %@", iVC.model);
                        NSLog(@"🔴 model liked %s", iVC.model.isLiked ? "true" : "false");
                    }
                }
            }
        }
    }
    
    if ([sender isKindOfClass:[MainCollectionViewCell class]]) {
        NSIndexPath *indexPath = [self.nasaCollectionView indexPathForCell:sender];
        if (indexPath) {
            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"showSelectedCell"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[NastarsaSingleImageVC class]]) {
                    NastarsaSingleImageVC *nSIVC = (NastarsaSingleImageVC *)segue.destinationViewController;
//                    nSIVC.photoSetup = _likedPhotoArray[indexPath.row];
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

    Photo *photoModel = [self.frc objectAtIndexPath:indexPath];
    if (photoModel) {
        NSLog(@"called");
        [cell configure:photoModel];
    }
    NSLog(@"cell for Item called");
    [self settingGesturesWith:cell.imageView];
    cell.imageView.tag = indexPath.row;
    
    return cell;
}

#pragma mark - <UIScrollView>

//- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
//   
//    if (indexPath.row == (self.photos.count - 1)){
//        if ((self.pageNumber > 1) && !isPageRefreshing) {
//            isPageRefreshing = YES;
//            self.pageNumber -= 1;
//            NSLog(@"fetching from page: %d", self.pageNumber);
//            [self.spinnerWhenNextPageDownload startAnimating];
//            [NasaFetcher fetchPhotos: self.pageNumber];
//        }
//    }
//}

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"size for Item called");
    
    CGSize size = self.view.frame.size;
    Photo *photoModel = [self.frc objectAtIndexPath:indexPath];
    
//    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    
    //    if (cell.isSelected) { // We know that we have to enlarge at least one cell
    //        [cell settingLargeImage:imageModel];
    //        cell.imageBottomConstraint = [cell.image.bottomAnchor constraintEqualToAnchor:cell.bottomAnchor constant:0];
    //        cell.imageBottomConstraint.active = YES;
    //        return CGSizeMake(size.width, size.height);
    //
    //    } else {
    
    CGFloat approximateWidth = size.width - 32;
    CGSize sizeForLabel = CGSizeMake(approximateWidth, CGFLOAT_MAX);
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:12.0f] };
    
    CGRect estimatedSizeOfLabel = [photoModel.someDescription boundingRectWithSize:sizeForLabel
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                        attributes:attributes
                                                                           context:nil];
    
    CGRect estimatedSizeOfTitle = [photoModel.title boundingRectWithSize:sizeForLabel
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                                 context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 45 - 5;//different inset: delete -5? 
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // Device is iPad
        size = CGSizeMake((size.width - paddingBetweenCells)/3 - inset, (size.width - paddingBetweenLines)/3 - inset + 125 + 45);
    } else {
        if (photoModel.isExpanded == YES && heightForItem > size.width + 125 + 45) {
            NSLog(@"somehow it's triggered 😀");
            size = CGSizeMake(size.width, heightForItem);
        } else {
            if (heightForItem < size.width + 125 + 45) {
                NSLog(@"heightForItem < size.width + 125");
                photoModel.isExpanded = YES;
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

#pragma mark - <UICollectionViewDelegate>



#pragma mark - <ExpandedAndButtonsTouchedCellDelegate>

- (void)readMoreButtonTouched:(NSIndexPath *)indexPath {
    
    Photo *photoModel = [self.frc objectAtIndexPath:indexPath];
    photoModel.isExpanded = !photoModel.isExpanded;
    
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
    
    Photo *photoModel = [self.frc objectAtIndexPath:indexPath];
    photoModel.isLiked = !photoModel.isLiked;
    
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    
    if (photoModel.isLiked) {
        cell.likeButton.selected = YES;
//        [Photo saveNewLikedPhotoFrom:imageModel preview:cell.imageView.image inContext:moc];
    } else {
        cell.likeButton.selected = NO;
//        [Photo deleteLikedPhotoFrom:imageModel.nasa_id inContext:moc];
    }
}

- (void)checkingLoadedPhotoWasLiked {
    if (_context) {
        NSLog(@"🔶🔷");
        
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            NSError *error = nil;
            NSArray <Photo *> *likedPhotoArray = [_context executeFetchRequest:fetchRequest error:&error];
            NSUInteger count = [_context countForFetchRequest:fetchRequest error:&error];
            NSLog(@"%lu liked images", (unsigned long) count);
            
            if (count > 0) {
                for (Photo *photo in likedPhotoArray) {
                    for (ImageModel *loadedPhoto in _photos) {
                        if ([photo.title isEqual:loadedPhoto.title]) {
                            NSLog(@"🔷");
                            loadedPhoto.isLiked = YES;
                            break;
                        }
                    }
                }
            }
    }
}

- (void)someReactionFrom:(NSNotification *) notification {
    NSDictionary *userInfo = notification.userInfo;
    for(id key in userInfo)
        NSLog(@"key=%@ value=%@", key, [userInfo objectForKey:key]);
//    NSLog(@"✅✅✅ @%", userInfo);
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.shouldReloadCollectionView = NO;
    self.blockOperation = [[NSBlockOperation alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    __weak UICollectionView *collectionView = self.nasaCollectionView;
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.blockOperation addExecutionBlock:^{
                [collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            [self.blockOperation addExecutionBlock:^{
                [collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            break;
        }
            
        case NSFetchedResultsChangeUpdate: {
            [self.blockOperation addExecutionBlock:^{
                [collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    __weak UICollectionView *collectionView = self.nasaCollectionView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            if ([self.nasaCollectionView numberOfSections] > 0) {
                if ([self.nasaCollectionView numberOfItemsInSection:indexPath.section] == 0) {
                    self.shouldReloadCollectionView = YES;
                } else {
                    [self.blockOperation addExecutionBlock:^{
                        [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
                    }];
                }
            } else {
                self.shouldReloadCollectionView = YES;
            }
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            if ([self.nasaCollectionView numberOfItemsInSection:indexPath.section] == 1) {
                self.shouldReloadCollectionView = YES;
            } else {
                [self.blockOperation addExecutionBlock:^{
                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }];
            }
            break;
        }
            
        case NSFetchedResultsChangeUpdate: {
            [self.blockOperation addExecutionBlock:^{
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }];
            break;
        }
            
        case NSFetchedResultsChangeMove: {
            [self.blockOperation addExecutionBlock:^{
                [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
    if (self.shouldReloadCollectionView) {
        [self.nasaCollectionView reloadData];
    } else {
        [self.nasaCollectionView performBatchUpdates:^{
            [self.blockOperation start];
        } completion:nil];
    }

}


@end
