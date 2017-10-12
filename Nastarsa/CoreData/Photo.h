//
//  Photo.h
//  Nastarsa
//
//  Created by Artur Kablak on 10/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NasaFetcher.h"

@interface Photo : NSManagedObject

+ (Photo *)photoWithInfo:(ImageModel *)imageModel inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)printDatabaseStatistics:(NSManagedObjectContext *)context;
+ (void)saveNewLikedPhotoFrom:(ImageModel *)imageModel;
+ (void)deleteLikedPhotoFrom:(ImageModel *)imageModel;

@end
