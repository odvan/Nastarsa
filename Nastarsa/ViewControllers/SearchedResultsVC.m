//
//  SearchedResultsVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 06/12/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "SearchedResultsVC.h"
#import "NasaFetcher.h"
#import "SearchHeader.h"

static NSString * const searchHeaderIdentifier = @"searchHeader";

@interface SearchedResultsVC () <UISearchBarDelegate>

@property (nonatomic, assign) int pageNumber;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL searchBarHasText;
@property (nonatomic, assign) int lastPage;
@property (nonatomic, assign) BOOL isPageRefreshing;

@property (nonatomic, strong) UIView *blackView;

@end

@implementation SearchedResultsVC


#pragma mark - View Controller Lifecycle

// Additional setups to parents viewDidLoad method

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photosData = [[NSMutableArray alloc] init];

    [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
        if (success) {
            _lastPage = numbers;
            _pageNumber = numbers;
            NSLog(@"got page number!");
            [NasaFetcher fetchPhotos:_searchText pageNumber:_lastPage withCompletion:^(BOOL success, NSMutableArray *photosData) {
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


#pragma mark - Properties lazy instantiation and setups

// whenever our Model is set, must update our View

- (void)setPhotosData:(NSMutableArray *)photosData {
    
    _isPageRefreshing = NO;
    [_photosData addObjectsFromArray:photosData];
    
    [self.backgroundContext performBlock:^{
        [Photo findOrCreatePhotosFrom:_photosData inContext:self.backgroundContext withPage:_pageNumber];
        NSError *error = nil;
        if (![self.backgroundContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:self.context];
        
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
                                                                                                               managedObjectContext:self.context
                                                                                                                 sectionNameKeyPath:nil
                                                                                                                          cacheName:nil];
        self.frc = newFetchedResultsController;
        
        [self.frc performFetch:&error];
        if (error) {
            NSLog(@"Unable to perform fetch.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.nasaCollectionView reloadData];
        });
    }];
}

- (void)setSearchText:(NSString *)text {
    NSLog(@"✅ setting search text: %@", text);
    if (_searchText != text) {
        _searchText = text;

        [self setBlackView];
        [self.spinnerWhenNextPageDownload startAnimating];
        
        [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
            if (success) {
                _lastPage = numbers;
                if (_searchText == nil) {
                    _pageNumber = _lastPage;
                } else {
                    _pageNumber = 1;
                }
                NSLog(@"got page number!");
                [NasaFetcher fetchPhotos:_searchText pageNumber:_pageNumber withCompletion:^(BOOL success, NSMutableArray *photosData) {
                    [self.spinnerWhenNextPageDownload stopAnimating];
                    [_blackView removeFromSuperview];
                    if (success) {
                        self.photosData = photosData;
                    } else {
                        [self showAlertWith:@"Error" message:@"Can't parse JSON."];
                    }
                }];
            } else {
                [self.spinnerWhenNextPageDownload stopAnimating];
                [_blackView removeFromSuperview];
                [self showAlertWith:@"Error" message:@"Can't download initial data."];
            }
        }];
    }
}

- (void)refreshControlSetup {
    UIRefreshControl *refreshControl;
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
        if (!_lastPage) {
            [NasaFetcher pageNumbersFrom:_searchText withCompletion:^(BOOL success, int numbers) {
                if (success) {
                    _lastPage = numbers;
                    _pageNumber = numbers;
                    NSLog(@"got page number!");
                } else {
                    [self showAlertWith:@"Error" message:@"Can't download initial data."];
                }
            }];
        } else {
            _pageNumber = _lastPage;
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

- (void)setBlackView {
    _blackView = [[UIView alloc] init];
    _blackView.frame = self.view.frame;
    _blackView.backgroundColor = [UIColor blackColor];
    _blackView.alpha = 0.75;
    [self.view insertSubview:_blackView atIndex:1];
}

#pragma mark - Setting Header in CollectionView

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
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    } else if (velocity.y < 0){
        NSLog(@"🔺🔺🔺 velocity: %f", velocity.y);
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    
    if (indexPath.row == ([sectionInfo numberOfObjects] - 1)) {
        if (_searchBarHasText) {
            if ((_pageNumber < _lastPage) && !_isPageRefreshing) {
                _isPageRefreshing = YES;
                self.pageNumber += 1;
            } else {
                return;
            }
        } else {
            if ((self.pageNumber > 1) && !_isPageRefreshing) {
                _isPageRefreshing = YES;
                self.pageNumber -= 1;
            } else {
                return;
            }
        }
        
        if (self.pageNumber <= _lastPage) {
            NSLog(@"fetching from page: %d", self.pageNumber);
            [self.spinnerWhenNextPageDownload startAnimating];
            [self setBlackView];

            [NasaFetcher fetchPhotos:_searchText pageNumber:self.pageNumber withCompletion:^(BOOL success, NSMutableArray *photosData) {
                if (success) {
                    [self.photosData removeAllObjects];
                    self.photosData = photosData;
                } else {
                    [self showAlertWith:@"Error" message:@"Can't download initial data."];
                }
                [self.spinnerWhenNextPageDownload stopAnimating];
                [_blackView removeFromSuperview];
            }];
        }
    }
}


#pragma mark - SearchBar Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [Photo deletePhotoObjects:self.context];
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
        
        [Photo deletePhotoObjects:self.context];
        [self.photosData removeAllObjects];
        searchBar.text = nil;
        self.searchText = nil;
    }
    _searchBarHasText = NO;
}


@end
