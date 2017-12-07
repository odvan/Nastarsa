//
//  NastarsaCollectionVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainCollectionViewCell.h"

@class Photo;

// Basic VC

@interface NastarsaCollectionVC : UIViewController <ExpandedAndButtonsTouchedCellDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet UICollectionView *nasaCollectionView;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;
@property (nonatomic, strong) NSFetchedResultsController<Photo *> *frc;

- (void)settingGesturesWith:(UIImageView *)imageView;

@end
