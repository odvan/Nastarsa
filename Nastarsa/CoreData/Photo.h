//
//  Photo.h
//  Nastarsa
//
//  Created by Artur Kablak on 10/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface Photo : NSManagedObject

+ (Photo *)photoWithInfoFrom:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context tempID:(int)temID;

+ (void)printDatabaseStatistics:(NSManagedObjectContext *)context;
+ (void)saveNewLikedPhotoFrom:(Photo *)photoObj inContext:(NSManagedObjectContext *)context;
+ (void)deleteLikedPhotoFrom:(Photo *)photoObj inContext:(NSManagedObjectContext *)context;

+ (void)findOrCreatePhotosFrom:(NSMutableArray *)photosData inContext:(NSManagedObjectContext *)context withPage:(int)pageNumber;
+ (void)deletePhotoObjects:(NSManagedObjectContext *)context;

@end
