//
//  SearchHeader.m
//  Nastarsa
//
//  Created by Artur Kablak on 27/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "SearchHeader.h"

@implementation SearchHeader

+ (NSString *)multipleWordsSearchCheckAndProperUsage:(NSString *)text {
    NSString *properMutlipleWordsSearchPhrase;
    NSArray *searchPhrase = [text componentsSeparatedByCharactersInSet:
                             [NSCharacterSet characterSetWithCharactersInString:@" "]
                             ];
    
    if (searchPhrase.count > 1) {
        properMutlipleWordsSearchPhrase = [searchPhrase componentsJoinedByString: @"%20"];
    } else {
        properMutlipleWordsSearchPhrase = text;
    }
    NSLog(@"search phrase %@",properMutlipleWordsSearchPhrase);
    return properMutlipleWordsSearchPhrase;
}

@end
