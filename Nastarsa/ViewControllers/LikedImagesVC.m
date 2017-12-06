//
//  LikedImagesVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 06/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "LikedImagesVC.h"
#import "LikedCell.h"
#import <CoreData/CoreData.h>
#import "Photo+CoreDataProperties.h"
#import "AppDelegate.h"
//#import "NastarsaSingleImageVC.h"
#import "SingleCellVC.h"

static NSString * const reuseIdentifier = @"likedImageCell";

static CGFloat paddingBetweenCells = 20;
static CGFloat paddingBetweenLines = 15;
static CGFloat inset = 20;
UILabel *noPhoto;

@interface LikedImagesVC () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;
@property (nonatomic, strong) NSBlockOperation *blockOperation;
@property (nonatomic, assign) BOOL shouldReloadCollectionView;
@property (nonatomic, assign) BOOL isSelectingPhotos;
@property (nonatomic, strong) NSMutableArray <Photo *> *addingSelectedPhotoObjects;

@end

@implementation LikedImagesVC

UIBarButtonItem *item1;
UIBarButtonItem *item2;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _likedImagesCollectionView.alwaysBounceVertical = YES;
    [self toolBarSetup];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self allowRotation:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"🎾🎾🎾🎾🎾");
    [self allowRotation:NO];
}


#pragma mark - Properties lazy instantiation

- (NSFetchedResultsController<Photo *> *)frc {
    NSLog(@"NSFetchedResultsController triggered");

    if (_frc != nil) {
        return _frc;
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.viewContext;
    NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isLiked == YES"]];

    // Initialize Fetched Results Controller
    NSFetchedResultsController<Photo *> *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                   managedObjectContext:_context
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

- (NSMutableArray <Photo *> *)addingSelectedPhotoObjects {
    
    if (_addingSelectedPhotoObjects != nil) {
        return _addingSelectedPhotoObjects;
    }
    NSMutableArray <Photo *> *array = [[NSMutableArray alloc] init];
    _addingSelectedPhotoObjects = array;
    return _addingSelectedPhotoObjects;
}


#pragma mark - <Methods and Actions>

- (void)setIsSelectingPhotos:(BOOL)isSelectingPhotos {
    
    _isSelectingPhotos = isSelectingPhotos;
    NSLog(@"🔴 selecting photos %s", self.isSelectingPhotos ? "true" : "false");
    
    self.navigationItem.rightBarButtonItem.title = self.isSelectingPhotos ? @"Cancel" : @"Select";
    self.navigationItem.rightBarButtonItem.style = self.isSelectingPhotos ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain;
    
    self.likedImagesCollectionView.allowsMultipleSelection = self.isSelectingPhotos;
    [self.navigationController setToolbarHidden:!self.isSelectingPhotos];
    item1.enabled = NO;
    item2.enabled = NO;
    [self.navigationItem setHidesBackButton:self.isSelectingPhotos animated:NO];
    
    [self.likedImagesCollectionView selectItemAtIndexPath:nil
                                                 animated:NO
                                           scrollPosition:UICollectionViewScrollPositionNone];
    self.title = self.isSelectingPhotos ? @"Select photo" : @"liked";
    
    if (!_isSelectingPhotos) {
        [self.addingSelectedPhotoObjects removeAllObjects];
    }
}

- (void)selectPhotos:(UIBarButtonItem *)sender {
  
    self.isSelectingPhotos = !self.isSelectingPhotos;
}

- (void)updateSharePhotoCount {
    item1.enabled = self.addingSelectedPhotoObjects.count > 0 ? YES : NO;
    item2.enabled = self.addingSelectedPhotoObjects.count > 0 ? YES : NO;
    self.title = [NSString stringWithFormat:@"%lu photo selected", (unsigned long)_addingSelectedPhotoObjects.count];
    
}

- (void)toolBarSetup {
    UIImage *shareImage = [UIImage imageNamed:@"sharing-50"];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeSelectedPhoto:)];
    item2 = [[UIBarButtonItem alloc] initWithImage:shareImage style:UIBarButtonItemStylePlain target:self action:@selector(shareSelectedPhoto:)];
    [item1 setEnabled:NO];
    [item2 setEnabled:NO];
    NSArray *items = [NSArray arrayWithObjects:item2, flexibleItem, item1, nil];
    self.toolbarItems = items;
    [self.navigationController.toolbar setTintColor:[UIColor whiteColor]];
    [self.navigationController.toolbar setBarTintColor:[UIColor blackColor]];
    [self.navigationController.toolbar setBackgroundColor:[UIColor blackColor]];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [self.navigationController.toolbar setTranslucent:NO];
}

- (void)noPhotoMessage {
    noPhoto = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2-10, self.view.frame.size.width, 20)];
    noPhoto.text = @"No Liked Photo";
    [noPhoto setFont:[UIFont boldSystemFontOfSize:16]];
    [noPhoto setTextColor:[UIColor whiteColor]];
    [noPhoto setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:noPhoto];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)shareSelectedPhoto:(UIBarButtonItem *)sender {
    
    if (_addingSelectedPhotoObjects.count > 0) {
        
        NSMutableArray <UIImage *> *arrayOfImagesToShare = [[NSMutableArray alloc] init];
        
        for (Photo *imageToShare in _addingSelectedPhotoObjects) {
            NSLog(@"image %@", imageToShare.image_big);
            UIImage *image = [UIImage imageWithData:imageToShare.image_big ? imageToShare.image_big : imageToShare.image_preview];
            [arrayOfImagesToShare addObject:image];
        }
        
        NSLog(@"array %@", arrayOfImagesToShare);
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc]initWithActivityItems:arrayOfImagesToShare applicationActivities:nil];
        activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if (completed) {
                self.isSelectingPhotos = !self.isSelectingPhotos;
            }
        };
//        activityViewController.excludedActivityTypes = @[
//                                                         UIActivityTypePrint,
//                                                         UIActivityTypeCopyToPasteboard,
//                                                         UIActivityTypeAssignToContact,
//                                                         UIActivityTypeSaveToCameraRoll,
//                                                         UIActivityTypeAddToReadingList,
//                                                         UIActivityTypeAirDrop];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)removeSelectedPhoto:(UIBarButtonItem *)sender {

    if (_addingSelectedPhotoObjects.count > 0) {
        for (Photo *liked in _addingSelectedPhotoObjects) {
            [Photo deleteLikedPhotoFrom:liked inContext:_context];
        }
    }
    [self.addingSelectedPhotoObjects removeAllObjects];
    [self updateSharePhotoCount];
    self.isSelectingPhotos = !self.isSelectingPhotos;
}

- (void)allowRotation:(BOOL)yesOrNo {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.shouldRotate = yesOrNo;
}


#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][section];
    if ([sectionInfo numberOfObjects] == 0) {
        [self noPhotoMessage];
    } else {
        UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(selectPhotos:)];
        [self.navigationItem setRightBarButtonItem:select animated:NO];
        [noPhoto removeFromSuperview];
    }
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LikedCell *cell = [self.likedImagesCollectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    Photo *likedPhoto = [self.frc objectAtIndexPath:indexPath];

    if (likedPhoto != nil) {
        NSLog(@"%@", likedPhoto.title);
        [cell configure:likedPhoto];
    }
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSLog(@"size for Item called");
    
    CGSize size = self.view.frame.size;
    size = CGSizeMake((size.width - 3 * paddingBetweenCells)/2, (size.width - 3 * paddingBetweenCells)/2 + 29);
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
        return UIEdgeInsetsMake(inset, inset, inset, inset);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return paddingBetweenCells;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return paddingBetweenLines;
}

#pragma mark - <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    __weak LikedCell *someCell = (LikedCell*)[self.likedImagesCollectionView cellForItemAtIndexPath:indexPath];
    
    if (self.isSelectingPhotos) {
        someCell.isSelectable = YES;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"hey YOU");

    __weak LikedCell *someCell = (LikedCell*)[self.likedImagesCollectionView cellForItemAtIndexPath:indexPath];
    Photo *selected = [self.frc objectAtIndexPath:indexPath];
    
    if (!self.isSelectingPhotos) {
        [self performSegueWithIdentifier: @"showSingleCell" sender: someCell];
    } else {
        [self.addingSelectedPhotoObjects addObject:selected];
        [self updateSharePhotoCount];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"didDeselect");

    if (self.isSelectingPhotos) {
        Photo *deSelected = [self.frc objectAtIndexPath:indexPath];
        NSInteger index = [self.addingSelectedPhotoObjects indexOfObject:deSelected];
        if (index >= 0) {
            [self.addingSelectedPhotoObjects removeObjectAtIndex:index];
            [self updateSharePhotoCount];
        }

    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([sender isKindOfClass:[LikedCell class]]) {
        NSIndexPath *indexPath = [self.likedImagesCollectionView indexPathForCell:sender];
        __weak LikedCell *cell = (LikedCell *)[self.likedImagesCollectionView cellForItemAtIndexPath:indexPath];
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.shouldReloadCollectionView = NO;
    self.blockOperation = [[NSBlockOperation alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    __weak UICollectionView *collectionView = self.likedImagesCollectionView;
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
    __weak UICollectionView *collectionView = self.likedImagesCollectionView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            if ([self.likedImagesCollectionView numberOfSections] > 0) {
                if ([self.likedImagesCollectionView numberOfItemsInSection:indexPath.section] == 0) {
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
            if ([self.likedImagesCollectionView numberOfItemsInSection:indexPath.section] == 1) {
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
        [self.likedImagesCollectionView reloadData];
    } else {
        [self.likedImagesCollectionView performBatchUpdates:^{
            [self.blockOperation start];
        } completion:nil];
    }
}

@end
