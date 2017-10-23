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

+ (Photo *)photoWithInfo:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context {
    Photo *photo = nil;
    photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                          inManagedObjectContext:context];
    NSLog(@"⚽️");
    
    photo.title = [dictionary objectForKey:@"title"];
    photo.nasa_id = [dictionary objectForKey:@"nasa_id"];
    photo.someDescription = [dictionary objectForKey:@"description"];
    photo.link = [NasaFetcher urlStringForPhoto:photo.nasa_id format:NasaPhotoFormatThumb];
    photo.isExpanded = NO;
    photo.isLiked = NO;
//    photo.image_preview = [NSData dataWithContentsOfURL:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatThumb]]; //UIImageJPEGRepresentation(image, 1.0);//
//    
//    NSData *bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatLarge]];
//    if (bigSizeImage) {
//        photo.image_big = bigSizeImage;
//    } else {
//        bigSizeImage = [[NSData alloc] initWithContentsOfURL:[NasaFetcher URLforPhoto:photo.nasa_id format:NasaPhotoFormatOriginal]];
//        if (bigSizeImage) {
//            photo.image_big = bigSizeImage;
//        } else {
//            photo.image_big = nil;
//        }
//    }
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
            NSLog(@"Running on %@ thread (statistics)", [NSThread currentThread]);
//            NSLog(@"%lu registeredObjects count", [[context registeredObjects] count]);
        }];
    } else {
        NSLog(@"💩");
    }
}

+ (void)saveNewLikedPhotoFrom:(ImageModel *)imageModel preview:(UIImage *)image inContext:(NSManagedObjectContext *)context {
    
    if (context) {
        NSLog(@"🎾 create new Photo entity");
        [context performBlock:^{
            NSLog(@"Running on %@ thread (saving)", [NSThread currentThread]);
            
//            [Photo photoWithInfo:imageModel inManagedObjectContext:context];
            
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

+ (void)deleteLikedPhotoFrom:(NSString *)image_id inContext:(NSManagedObjectContext *)context {
    //    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (context) {//(appDelegate.persistentContainer.viewContext) {
        //        NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
        NSLog(@"🖕🖕🖕");
        //        [appDelegate.persistentContainer performBackgroundTask:^(NSManagedObjectContext *context) {
        
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        context.parentContext = appDelegate.persistentContainer.viewContext;
        [context performBlock:^{
            NSLog(@"Running on %@ thread (deleting)", [NSThread currentThread]);
            NSFetchRequest<Photo *> *fetchRequest = Photo.fetchRequest;
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nasa_id == %@", image_id]];
            NSError *error = nil;
            NSArray *someArray = [context executeFetchRequest:fetchRequest error:&error];
            if (someArray.count > 0) {
                [context deleteObject:[someArray firstObject]];
                if (![context save:&error]) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
                [appDelegate.persistentContainer.viewContext performBlock:^{
                    NSError *error;
                    if (![appDelegate.persistentContainer.viewContext save:&error]) {
                        // handle error
                    }
                }];
            }
            [Photo printDatabaseStatistics:context];
        }];
    }
}

@end
