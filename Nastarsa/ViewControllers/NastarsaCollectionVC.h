//
//  NastarsaCollectionVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"
#import <CoreData/CoreData.h>
#import "Photo.h"
#import "Photo+CoreDataProperties.h"
#import "MainCollectionViewCell.h"

@interface NastarsaCollectionVC : UIViewController <ExpandedAndButtonsTouchedCellDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet UICollectionView *nasaCollectionView;

///
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinnerWhenNextPageDownload;
///

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;
@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;

///
// Model of this MVC (it can be publicly set)
@property (nonatomic, strong) NSMutableArray *photosData;
///

- (void)settingGesturesWith:(UIImageView *)imageView;

@end
