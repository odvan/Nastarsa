//
//  NastarsaCollectionVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaCollectionVC.h"
#import "MainCollectionViewCell.h"
#import "ImageModel.h"
#import "NasaFetcher.h"

static NSCache * imagesCache;
static NSString * const reuseIdentifier = @"imageCell";
int lastPage = 0;
BOOL isPageRefreshing = NO;
CGSize size;
UIRefreshControl *refreshControl;
NSIndexPath *selectedIndexPath;


static CGFloat paddingBetweenCells = 10;
static CGFloat paddingBetweenLines = 10;
static CGFloat inset = 10;

@interface NastarsaCollectionVC ()

@property (nonatomic, assign) int pageNumber;
@end

@implementation NastarsaCollectionVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photos = [[NSMutableArray alloc] init];
    imagesCache = [[NSCache alloc] init];
   
    _nasaCollectionView.allowsMultipleSelection = YES;
    
    
//    _layout.estimatedItemSize = CGSizeMake(100, 100); //UICollectionViewFlowLayoutAutomaticSize;
////    _layout.itemSize = CGSizeMake(300, 300);
//    _nasaCollectionView.collectionViewLayout = _layout;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //    [self.collectionView registerClass:[MainCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [NasaFetcher pageNumbers:^(int numbers) {
        lastPage = numbers;
        _pageNumber = numbers;
        NSLog(@"fuck it");
        [NasaFetcher fetchPhotos: lastPage
                  withCompletion:^(NSMutableArray <ImageModel *> *photos) {
                      self.photos = photos;
                  }];
    }];
    
    [self refreshControlSetup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// whenever our Model is set, must update our View

- (void)setPhotos:(NSMutableArray *)photos {
    isPageRefreshing = NO;
    [_photos addObjectsFromArray:photos];
    [self.nasaCollectionView reloadData];
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
              withCompletion:^(NSMutableArray <ImageModel *> *photos) {
                  [self.nasaCollectionView.refreshControl endRefreshing];
                  [self.photos removeAllObjects];
                  self.photos = photos;
              }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.photos.count > 1) {
        NSLog(@"%lu", (unsigned long)_photos.count);
        return self.photos.count;
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MainCollectionViewCell *cell = [self.nasaCollectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    ImageModel *imageModel = _photos[indexPath.row];
    if (imageModel) {
        NSLog(@"called");
        [cell configure:imageModel];
    }
    // Configure the cell
    
    return cell;
}

#pragma mark <UIScrollView>

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    if (self.nasaCollectionView.contentOffset.y >= (self.nasaCollectionView.contentSize.height - self.nasaCollectionView.bounds.size.height)) {
//        
//        
//        if ((self.pageNumber > 1) && !isPageRefreshing) {
//            isPageRefreshing = YES;
//            self.pageNumber -= 1;
//            NSLog(@"fetching from page: %d", self.pageNumber);
//            [self.spinnerWhenNextPageDownload startAnimating];
//            [NasaFetcher fetchPhotos: self.pageNumber
//                      withCompletion:^(NSMutableArray <ImageModel *> *photos) {
//                          self.photos = photos;
//                          [self.spinnerWhenNextPageDownload stopAnimating];
//                      }];
//        }
//    }
//}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
   
    if (indexPath.row == (self.photos.count - 1)){
        if ((self.pageNumber > 1) && !isPageRefreshing) {
            isPageRefreshing = YES;
            self.pageNumber -= 1;
            NSLog(@"fetching from page: %d", self.pageNumber);
            [self.spinnerWhenNextPageDownload startAnimating];
            [NasaFetcher fetchPhotos: self.pageNumber
                      withCompletion:^(NSMutableArray <ImageModel *> *photos) {
                          self.photos = photos;
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
    ImageModel *imageModel = _photos[indexPath.row];

    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    
    if (cell.isSelected) { // We know that we have to enlarge at least one cell
        [cell settingLargeImage:imageModel];
        return CGSizeMake(size.width - 2*inset, size.height);
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            size = CGSizeMake((size.width - paddingBetweenCells)/3 - inset, (size.width - paddingBetweenLines)/3 - inset); // Device is iPad
        
        } else {
            CGFloat approximateWidth = size.width - 32;
            CGSize sizeForLabel = CGSizeMake(approximateWidth, CGFLOAT_MAX);
            NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Avenir-Book" size:8.0f] };
            
            CGRect estimatedSizeOfLabel = [imageModel.someDescription boundingRectWithSize:sizeForLabel
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:attributes context:nil];
            
            size = CGSizeMake(size.width - 2*inset, estimatedSizeOfLabel.size.height + 20 + size.width - 2*inset);
        }
        return size;
    }
    
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

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/


// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];

    if (cell.isSelected) {        
        return NO;
    } else {
        [cell.title setHidden: YES];
        [cell.imageDescription setHidden: YES];
        [cell.paddingView setHidden: YES];
        NSLog(@"SELECTED");
        return YES;
    }

    return cell.isSelected;
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    
    if (cell.isSelected) {
        [cell.title setHidden: NO];
        [cell.imageDescription setHidden: NO];
        [cell.paddingView setHidden: NO];
        NSLog(@"DE-SELECTED");

        return YES;
    } else {
        return NO;
    }

}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"when SELECTED");
    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];

    if (cell.isSelected) {
        NSArray *indexes = [[NSArray alloc] init];
        [indexes arrayByAddingObject:indexPath];
        [self.nasaCollectionView reloadItemsAtIndexPaths:indexes];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"when DE-SELECTED");

    __weak MainCollectionViewCell *cell = (MainCollectionViewCell*)[self.nasaCollectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.isSelected) {
        NSArray *indexes = [[NSArray alloc] init];
        [indexes arrayByAddingObject:indexPath];
        [self.nasaCollectionView reloadItemsAtIndexPaths:indexes];
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
