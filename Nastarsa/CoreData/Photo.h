//
//  Photo.h
//  Nastarsa
//
//  Created by Artur Kablak on 10/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "NasaFetcher.h"

@interface Photo : NSManagedObject

+ (Photo *)photoWithInfo:(ImageModel *)imageModel preview:(UIImage *)image inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)printDatabaseStatistics:(NSManagedObjectContext *)context;
+ (void)saveNewLikedPhotoFrom:(ImageModel *)imageModel preview:(UIImage *)image inContext:(NSManagedObjectContext *)context;
+ (void)deleteLikedPhotoFrom:(ImageModel *)imageModel inContext:(NSManagedObjectContext *)context;

@end
