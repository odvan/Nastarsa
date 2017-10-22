//
//  LikedImagesVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 06/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LikedImagesVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *likedImagesCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end
