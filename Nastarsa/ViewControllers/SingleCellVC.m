//
//  SingleCellVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 29/11/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "SingleCellVC.h"
#import "AppDelegate.h"
#import "ExampleCell.h"


@interface SingleCellVC () 

@end

@implementation SingleCellVC

- (void)viewDidLoad {
//    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.backgroundContext = appDelegate.persistentContainer.newBackgroundContext;
    self.context = appDelegate.persistentContainer.newBackgroundContext;
    self.context.automaticallyMergesChangesFromParent = YES;
        
    self.title = @"photo";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tempID" ascending:NO]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", _photoObjSetupDouble.nasa_id]];
    NSError *error = nil;

    // Initialize Fetched Results Controller
    NSFetchedResultsController<Photo *> *newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                           managedObjectContext:self.context
                                                                                                             sectionNameKeyPath:nil
                                                                                                                      cacheName:nil];
    self.frc = newFetchedResultsController;
    
    [self.frc performFetch:&error];
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
    [self.nasaCollectionView reloadData];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

#pragma mark - Properties lazy instantiation

- (void)setPhotoSetup:(Photo *)photoObjSetupDouble {
    if (_photoObjSetupDouble != photoObjSetupDouble) {
        _photoObjSetupDouble = photoObjSetupDouble;
    }
}


#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoObjSetupDouble != nil ? 1 : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExampleCell *cell = [self.nasaCollectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.delegate = self;
    cell.indexPath = indexPath;
    
    [cell configure:_photoObjSetupDouble];
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
    
    CGRect estimatedSizeOfLabel = [_photoObjSetupDouble.someDescription boundingRectWithSize:sizeForLabel
                                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                                            attributes:attributes
                                                                               context:nil];
    
    CGRect estimatedSizeOfTitle = [_photoObjSetupDouble.title boundingRectWithSize:sizeForLabel
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Black" size:16.0f] }
                                                                     context:nil];
    
    CGFloat heightForItem = ceil(estimatedSizeOfTitle.size.height) + ceil(estimatedSizeOfLabel.size.height) + 16 + 10 + size.width + 44;
    size = CGSizeMake(size.width, heightForItem);
    NSLog(@"setting size: height %f", heightForItem);
    return size;
}


@end
