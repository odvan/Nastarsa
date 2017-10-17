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

static CGFloat paddingBetweenCells = 15;
static CGFloat paddingBetweenLines = 15;
static CGFloat inset = 15;
UILabel *noPhoto;

@interface LikedImagesVC ()

@property (nonatomic, strong) NSArray <Photo *> *likedPhotoArray;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation LikedImagesVC

- (void)viewDidLoad {
    [super viewDidLoad];

    _likedImagesCollectionView.alwaysBounceVertical = YES;
    
    [self loadingLikedPhoto];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(loadingLikedPhoto)
     name:NSManagedObjectContextDidSaveNotification
     object:nil];
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    [self loadingLikedPhoto];
//}

- (void)loadingLikedPhoto {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.persistentContainer.viewContext) {
        _context = appDelegate.persistentContainer.viewContext;
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

- (void)setLikedPhotosArray:(NSArray <Photo *> *)photos { // ??? doen't needed
    NSLog(@"just show something");
    _likedPhotoArray = photos;
    [self.likedImagesCollectionView reloadData];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _likedPhotoArray.count > 0 ? _likedPhotoArray.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LikedCell *cell = [self.likedImagesCollectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    Photo *likedPhoto = _likedPhotoArray[indexPath.row];
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
    size = CGSizeMake((size.width - 3*paddingBetweenLines)/2, (size.width - 3*paddingBetweenLines)/2 + 29);
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
                    nSIVC.photoSetup = _likedPhotoArray[indexPath.row];
                }
            }
        }
    }
}

@end
