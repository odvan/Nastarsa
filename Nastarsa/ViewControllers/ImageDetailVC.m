//
//  ImageDetailVC.m
//  Nastarsa
//
//  Created by Artur Kablak on 13/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "ImageDetailVC.h"

@interface ImageDetailVC ()

@end

@implementation ImageDetailVC

- (instancetype)init
{
    if (self = [super init]) {
        self.nasaCollectionView = [[UICollectionView alloc] init];
        self.photos = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
//    [super viewDidLoad];
    
//    _photos = [[NSMutableArray alloc] init];
//    imagesCache = [[NSCache alloc] init];
    
    self.nasaCollectionView.alwaysBounceVertical = YES;

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
