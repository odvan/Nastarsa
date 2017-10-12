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

+ (Photo *)photoWithInfo:(ImageModel *)imageModel inManagedObjectContext:(NSManagedObjectContext *)context {
    Photo *photo = nil;
    photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                          inManagedObjectContext:context];
    NSLog(@"⚽️");
    photo.title = imageModel.title;
    photo.link = imageModel.link.absoluteString;
    photo.nasa_id = imageModel.nasa_id;
    photo.someDescription = imageModel.someDescription;
    photo.image_preview = [NSData dataWithContentsOfURL:imageModel.link];//contentsOf: URL(string: recipe.imageUrl)];
    
    NSData *bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:imageModel.nasa_id format:NasaPhotoFormatLarge]];
    if (bigSizeImage) {
        photo.image_big = bigSizeImage;
    } else {
        bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:imageModel.nasa_id format:NasaPhotoFormatOriginal]];
        if (bigSizeImage) {
            photo.image_big = bigSizeImage;
        } else {
            photo.image_big = nil;
        }
    }
    NSLog(@"%@ photo entity", photo.title);
    return photo;
}

+ (void)printDatabaseStatistics:(NSManagedObjectContext *)context {
    if (context) {
        NSLog(@"⚽️⚽️");
        [context performBlock:^{
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            fetchRequest.predicate = nil;
            NSError *error = nil;
            NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
            NSLog(@"%lu liked images", (unsigned long)count);
        }];
    } else {
        NSLog(@"💩");
    }
}

+ (void)saveNewLikedPhotoFrom:(ImageModel *)imageModel {

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.persistentContainer.viewContext) {
        NSLog(@"🖕💩💩");
        [appDelegate.persistentContainer performBackgroundTask:^(NSManagedObjectContext *context) {
            
            [Photo photoWithInfo:imageModel inManagedObjectContext:context];
            
            NSError *error = nil;
            if (![context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
            [Photo printDatabaseStatistics:context];
        }];
    }
}

+ (void)deleteLikedPhotoFrom:(ImageModel *)imageModel {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.persistentContainer.viewContext) {
        NSLog(@"🖕🖕🖕");
        [appDelegate.persistentContainer performBackgroundTask:^(NSManagedObjectContext *context) {
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", imageModel.nasa_id]];
            NSError *error = nil;
            NSArray *someArray = [context executeFetchRequest:fetchRequest error:&error];
            [context deleteObject:[someArray firstObject]];
            if (![context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
            [Photo printDatabaseStatistics:context];
        }];
    }
}

@end
