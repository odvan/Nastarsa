//
//  Photo.m
//  Nastarsa
//
//  Created by Artur Kablak on 10/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "Photo.h"
#import "Photo+CoreDataProperties.h"
#import "AppDelegate.h"

@implementation Photo

+ (Photo *)photoWithInfoFrom:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context tempID:(int)tempID {
    Photo *photo = nil;
    photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                          inManagedObjectContext:context];
    NSLog(@"⚽️ creating managed obj");
    photo.tempID = tempID;
    photo.title = [dictionary objectForKey:@"title"];
    photo.nasa_id = [dictionary objectForKey:@"nasa_id"];
    photo.someDescription = [dictionary objectForKey:@"description"];
    photo.isExpanded = NO;
    photo.isLiked = NO;
    photo.isFetchable = YES;
    photo.link = [NasaFetcher URLStringForPhoto:photo.nasa_id format:NasaPhotoFormatThumb];
    
    NSLog(@"%@ photo entity", photo.title);
    NSLog(@"🛑 %d photo tempID", photo.tempID);

    return photo;
}


+ (void)printDatabaseStatistics:(NSManagedObjectContext *)context {
    if (context) {
        NSLog(@"✅ printDatabaseStatistics");
        [context performBlock:^{
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            fetchRequest.predicate = nil;
//            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isFetchable == NO"]];

            NSError *error = nil;
            NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
            NSLog(@"%lu fetched/liked images", (unsigned long)count);
            NSLog(@"Running on %@ thread (statistics)", [NSThread currentThread]);
        }];
    } else {
        NSLog(@"💩");
    }
}


+ (void)saveNewLikedPhotoFrom:(Photo *)photoObj inContext:(NSManagedObjectContext *)context {
    
    [context performBlock:^{
        NSLog(@"Running on %@ thread (Liked)", [NSThread currentThread]);
        NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", photoObj.nasa_id]];
        NSError *error = nil;
        NSArray <Photo *> *photoExisted = [context executeFetchRequest:fetchRequest error:&error];
        
        if (photoExisted != nil) {
            photoExisted[0].isLiked = YES;
            photoExisted[0].isFetchable = NO; // ?
            photoExisted[0].image_preview = photoObj.image_preview;
            if (photoObj.image_big != nil) {
                photoExisted[0].image_big = photoObj.image_big;
            } else {
                NSData *bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:photoObj.nasa_id format:NasaPhotoFormatLarge]];
                if (bigSizeImage) {
                    photoExisted[0].image_big = bigSizeImage;
                } else {
                    bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:photoObj.nasa_id format:NasaPhotoFormatOriginal]];
                    if (bigSizeImage) {
                        photoExisted[0].image_big = bigSizeImage;
                    } else {
                        photoExisted[0].image_big = nil;
                    }
                }
            }
        }
        
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:context];
    }];
}


+ (void)deleteLikedPhotoFrom:(Photo *)photoObj inContext:(NSManagedObjectContext *)context {
    
    [context performBlock:^{
        NSLog(@"Running on %@ thread (disLiked)", [NSThread currentThread]);
        
        NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", photoObj.nasa_id]];
        NSError *error = nil;
        NSArray <Photo *> *photoExisted = [context executeFetchRequest:fetchRequest error:&error];
        if (photoExisted != nil) {
            photoExisted[0].isLiked = NO;
            photoExisted[0].isFetchable = YES;
        }
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:context];
    }];
}


+ (void)findOrCreatePhotosFrom:(NSMutableArray *)photosData inContext:(NSManagedObjectContext *)context withPage:(int)pageNumber {
    int numberInArray = 0;
    for (NSMutableDictionary *photoDictionary in photosData) {
        
        NSArray *photo = [photoDictionary objectForKey: NASA_PHOTO_DATA];
        if (photo) {
            numberInArray += 1;
            NSDictionary *dictionary = photo.firstObject;
            NSString *nasa_id = [dictionary objectForKey:@"nasa_id"];
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", nasa_id]];
            NSError *error = nil;
            NSArray <Photo *> *photoExisted = [context executeFetchRequest:fetchRequest error:&error];
            
            if (photoExisted.count > 0 && photoExisted.count < 2) {
                NSLog(@"something existed: %@", photoExisted.firstObject.title);
                Photo *existed = photoExisted.firstObject;
                existed.tempID = (pageNumber * 100) + numberInArray;
                existed.isFetchable = YES;
                continue;
            } else {
                // some mistake
            }
            [self photoWithInfoFrom:dictionary inManagedObjectContext:context tempID:((pageNumber * 100) + numberInArray)];
        }
    }
}


+ (void)deletePhotoObjects:(NSManagedObjectContext *)context {
    
    [context performBlock:^{
        
        NSLog(@"Running on %@ thread (deleting all obj)", [NSThread currentThread]);
        NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            fetchRequest.predicate = nil;
        
        NSError *error = nil;
        NSArray *photoObjects = [context executeFetchRequest:fetchRequest error:&error];
        if (photoObjects.count > 0) {
            NSLog(@"deleting some obj");
            for (Photo *photo in photoObjects) {
                if (photo.isLiked) {
                    photo.isFetchable = NO;
                } else {
                    [context deleteObject:photo];
                }
            }
        }
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            abort();
        }
        [Photo printDatabaseStatistics:context];
    }];
}

@end
