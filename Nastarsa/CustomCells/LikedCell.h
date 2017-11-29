//
//  LikedCell.h
//  Nastarsa
//
//  Created by Artur Kablak on 06/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <CoreData/CoreData.h>
#import "Photo.h"
#import "Photo+CoreDataProperties.h"

@interface LikedCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *imageTitle;

- (void)configure:(Photo *)photo;

@end
