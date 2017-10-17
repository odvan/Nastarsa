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


static NSString * const reuseIdentifier = @"imageCell";

@interface NastarsaSingleImageVC () <ExpandedAndButtonsTouchedCellDelegate>

@property (nonatomic, strong) NSArray <Photo *> *likedPhotoArray;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation NastarsaSingleImageVC

- (void)viewDidLoad {
//    [super viewDidLoad];
    
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
//        [Photo saveNewLikedPhotoFrom:imageModel preview:cell.imageView.image inContext:_context];
    } else {
        [Photo deleteLikedPhotoFrom:_photoSetup.nasa_id inContext:_context];
    }
}


@end
