//
//  NastarsaSingleImageVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+CoreDataProperties.h"
#import "AppDelegate.h"
#import "NastarsaCollectionVC.h"

@interface NastarsaSingleImageVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet UICollectionView *singleImageCV;
@property (nonatomic, strong) Photo *photoObjSetup;

@end
