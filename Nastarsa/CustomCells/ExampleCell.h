//
//  ExampleCell.h
//  Nastarsa
//
//  Created by Artur Kablak on 16/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "Photo+CoreDataProperties.h"
#import "MainCollectionViewCell.h"

@interface ExampleCell : MainCollectionViewCell

- (void)configureWith:(Photo *)photo;
@end
