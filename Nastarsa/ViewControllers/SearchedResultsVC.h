//
//  SearchedResultsVC.h
//  Nastarsa
//
//  Created by Artur Kablak on 06/12/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaCollectionVC.h"
#import "NastarsaCollectionVC+AddAlert.h"

// Subclass from basic VC

@interface SearchedResultsVC : NastarsaCollectionVC

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinnerWhenNextPageDownload;
@property (nonatomic, strong) NSMutableArray *photosData;

@end
