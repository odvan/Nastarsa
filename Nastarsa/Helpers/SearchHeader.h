//
//  SearchHeader.h
//  Nastarsa
//
//  Created by Artur Kablak on 27/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

+ (NSString *)multipleWordsSearchCheckAndProperUsage:(NSString *)text;

@end
