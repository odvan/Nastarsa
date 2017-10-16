//
//  NastarsaCollectionVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 14/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"

@interface NastarsaCollectionVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (strong, nonatomic) IBOutlet UICollectionView *nasaCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinnerWhenNextPageDownload;

// Model of this MVC (it can be publicly set)
@property (nonatomic, strong) NSMutableArray <ImageModel *> *photos; // of ImageModel objects

@end
