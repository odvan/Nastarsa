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

@interface NastarsaSingleImageVC () <ExpandedAndButtonsTouchedCellDelegate>

//@property (nonatomic, strong) NSArray <Photo *> *likedPhotoArray;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation NastarsaSingleImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _singleImageCV.alwaysBounceVertical = YES;
    [self.singleImageCV registerNib:[UINib nibWithNibName:@"ExampleCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    
    
}

- (NSManagedObjectContext *)context {
    NSLog(@"setting context obj");
    if (_context != nil) {
        return _context;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.newBackgroundContext;
    return _context;
}

- (void)setPhotoSetup:(Photo *)photoSetup {
    if (_photoSetup != photoSetup) {
        _photoSetup = photoSetup;
    }
    NSLog(@"setting photoSetup obj: %@", _photoSetup);
    [self.singleImageCV reloadData];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoSetup != nil ? 1 : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExampleCell *cell = [self.singleImageCV dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.delegate = self;
    cell.indexPath = indexPath;
    
    [cell configureWith:_photoSetup];
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
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:12.0f] };
    
    CGRect estimatedSizeOfLabel = [_photoSetup.someDescription boundingRectWithSize:sizeForLabel
                                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                                         attributes:attributes
                                                                            context:nil];
    
    CGRect estimatedSizeOfTitle = [_photoSetup.title boundingRectWithSize:sizeForLabel
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                                  context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 45 - 5;//different inset: delete -5?
    
    size = CGSizeMake(size.width, heightForItem);
    NSLog(@"setting size: height %f", heightForItem);
    return size;
}

- (void)likedButtonTouched:(NSIndexPath *)indexPath {
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _context = appDelegate.persistentContainer.newBackgroundContext;
    
    NSLog(@"tapped liked");
    __weak ExampleCell *cell = (ExampleCell*)[self.singleImageCV cellForItemAtIndexPath:indexPath];
    cell.likeButton.selected = !cell.likeButton.selected;

    if (cell.likeButton.selected) {
        NSLog(@"❇️❇️❇️");
        [_context performBlock:^{
            NSLog(@"Running on %@ thread (saving)", [NSThread currentThread]);
            
            Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                                         inManagedObjectContext:_context];
            photo.title = _photoSetup.title;
            photo.link = _photoSetup.link;
            photo.nasa_id = _photoSetup.nasa_id;
            photo.someDescription = _photoSetup.someDescription;
            photo.image_preview = _photoSetup.image_preview;
            photo.image_big = _photoSetup.image_big;
            NSLog(@"photoSetup obj: %@", _photoSetup);
            NSError *error = nil;
            if (![_context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
            [Photo printDatabaseStatistics:_context];
        }];
    } else {
        [Photo deleteLikedPhotoFrom:_photoSetup.nasa_id inContext:_context];
        NSLog(@"photoSetup obj after deleting: %@", _photoSetup);
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
    [self performSegueWithIdentifier: @"showImageFromLikedVC" sender: gestureRecognizer];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
//        NSIndexPath *indexPath = [self.singleImageCV indexPathForCell:sender];
//        if (indexPath) {
//            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"showImageFromLikedVC"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    // yes ... then we know how to prepare for that segue!
//                    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.singleImageCV cellForItemAtIndexPath:indexPath];
                    ImageViewController *iVC = (ImageViewController *)segue.destinationViewController;
//                    iVC.tempImage = cell.imageView.image;
//                    iVC.imageURL = [NasaFetcher URLforPhoto:_photos[indexPath.row].nasa_id format:NasaPhotoFormatLarge];
//                    iVC.model = _photos[indexPath.row];
                    iVC.image = [UIImage imageWithData:_photoSetup.image_big];
                    iVC.likeButton.selected = YES;
                    NSLog(@"🔴 model liked %s", iVC.model.isLiked ? "true" : "false");
                }
            }
        }
//    }
}


@end
