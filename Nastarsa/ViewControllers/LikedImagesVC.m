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
#import "NastarsaSingleImageVC.h"

static NSString * const reuseIdentifier = @"likedImageCell";

static CGFloat paddingBetweenCells = 20;
static CGFloat paddingBetweenLines = 15;
static CGFloat inset = 20;
UILabel *noPhoto;

@interface LikedImagesVC () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSArray <Photo *> *likedPhotoArray;
@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;
@property (nonatomic, strong) NSBlockOperation *blockOperation;
@property (nonatomic, assign) BOOL shouldReloadCollectionView;

@end

@implementation LikedImagesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _likedImagesCollectionView.alwaysBounceVertical = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate setShouldRotate:YES];
}

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

- (void)loadingLikedPhoto {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.viewContext;
    if (_context) {
        [_context performBlock:^{
            NSLog(@"Running on %@ thread (liked VC)", [NSThread currentThread]);
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            fetchRequest.predicate = nil;
            NSError *error = nil;
            _likedPhotoArray = [_context executeFetchRequest:fetchRequest error:&error];
            NSUInteger count = [_context countForFetchRequest:fetchRequest error:&error];
            NSLog(@"%lu liked images", (unsigned long) count);
            if (count > 0) {
                [noPhoto removeFromSuperview];
                [self.likedImagesCollectionView reloadData];
            } else {
                [self noPhotoMessage];
                [self.likedImagesCollectionView reloadData];
            }
        }];
    }
}

- (void)noPhotoMessage {
    noPhoto = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2-10, self.view.frame.size.width, 20)];
    noPhoto.text = @"No Liked Photo";
    [noPhoto setFont:[UIFont boldSystemFontOfSize:16]];
    [noPhoto setTextColor:[UIColor whiteColor]];
    [noPhoto setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:noPhoto];
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
        [noPhoto removeFromSuperview];
    }
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LikedCell *cell = [self.likedImagesCollectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    Photo *likedPhoto = [self.frc objectAtIndexPath:indexPath];//_likedPhotoArray[indexPath.row];

    if (likedPhoto != nil) {
        NSLog(@"%@", likedPhoto.title);
        [cell configure:likedPhoto];
    }
    return cell;
}

#pragma mark <UICollectionViewDelegateFlowLayout>

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([sender isKindOfClass:[LikedCell class]]) {
        NSIndexPath *indexPath = [self.likedImagesCollectionView indexPathForCell:sender];
        if (indexPath) {
            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"showSingleCell"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[NastarsaSingleImageVC class]]) {
                    NastarsaSingleImageVC *nSIVC = (NastarsaSingleImageVC *)segue.destinationViewController;
                    Photo *object = [self.frc objectAtIndexPath:indexPath];
                    nSIVC.photoObjSetup = object;
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
    // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
    if (self.shouldReloadCollectionView) {
        [self.likedImagesCollectionView reloadData];
    } else {
        [self.likedImagesCollectionView performBatchUpdates:^{
            [self.blockOperation start];
        } completion:nil];
    }
//    // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
//    if (self.shouldReloadCollectionView) {
//        [self.likedImagesCollectionView reloadData];
//    } else {
//        [self.likedImagesCollectionView performBatchUpdates:^{
//            [[NSOperationQueue currentQueue] addOperation:self.blockOperation];
//        } completion:nil];
//    }
}

@end
