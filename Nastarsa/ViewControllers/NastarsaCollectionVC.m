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

@interface NastarsaCollectionVC ()

@end

@implementation NastarsaCollectionVC

static NSCache * imagesCache;
static NSString * const reuseIdentifier = @"imageCell";

// whenever our Model is set, must update our View

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    [self.nasaCollectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat width = self.view.frame.size.width;
    CGSize size = CGSizeMake(width, width + 70);
    _layout.itemSize = size;
    
    imagesCache = [[NSCache alloc] init];
//    self.collectionView.dataSource = self;
//    self.collectionView.delegate = self;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[MainCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    [self fetchPhotos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)fetchPhotos {
    //  [self.refreshControl beginRefreshing]; // start the spinner
    
    NSMutableArray <ImageModel *> *tempPhotosArray = [NSMutableArray array];
    
    NSURL *url = [[NSURL alloc] initWithString:@"https://images-api.nasa.gov/search?q=Moon&keywords=landing&media_type=image"];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("nasa fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Nasa
        NSData *jsonResults = [NSData dataWithContentsOfURL: url];
        NSError *error;
        
        // convert it to a Property List (NSArray and NSDictionary)
        NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:&error];
        
        if (error) {
            NSLog(@"Error parsing JSON: %@", error);
        }
        else {
            if ([propertyListResults isKindOfClass:[NSDictionary class]]) {
                NSLog(@"it is an array!");
                
                // get the NSArray of photo NSDictionarys out of the results
                NSArray *photosData = [propertyListResults valueForKeyPath: NASA_PHOTOS_ARRAY];
                
                if (photosData) {
                    for (NSMutableDictionary *item in photosData) {
                        if (item) {
                            NSArray *photoData = [item objectForKey: NASA_PHOTO_DATA];
                            if (photoData) {
                                ImageModel *photo = [[ImageModel alloc] initWithJSONDictionary: photoData.firstObject];
                                [tempPhotosArray addObject: photo];
                                NSLog(@"%@", [photo title]);
                                NSLog(@"%@", [photo link]);
                            }
                        }
                    }
                }
            }
        }
        // update the Model (and thus our UI), but do so back on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.refreshControl endRefreshing]; // stop the spinner
            self.photos = tempPhotosArray;
        });
    });
}


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
    
    ImageModel *imageModel = _photos[indexPath.row];
    if (imageModel) {
        NSLog(@"called");
        [cell configure: imageModel];
    }
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

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
