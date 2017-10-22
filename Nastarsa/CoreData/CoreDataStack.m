//
//  CoreDataStack.m
//  Nastarsa
//
//  Created by Artur Kablak on 22/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "CoreDataStack.h"

@implementation CoreDataStack

#pragma mark - NSManagedObjectContexts

+ (NSManagedObjectContext *)privateManagedObjectContext {
    if (!privateManagedObjectContext) {
        
        // Setup MOC attached to PSC
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        privateManagedObjectContext = appDelegate.persistentContainer.newBackgroundContext;
        
        // Add notification to perform save when the child is updated
        privateContextSaveObserver =
        [[NSNotificationCenter defaultCenter]
         addObserverForName:NSManagedObjectContextDidSaveNotification
         object:nil
         queue:nil
         usingBlock:^(NSNotification *note) {
             NSManagedObjectContext *savedContext = [note object];
             if (savedContext.parentContext == privateManagedObjectContext) {
                 [privateManagedObjectContext performBlock:^{
                     NSLog(@"CoreDataStack -> saving privateMOC");
                     NSError *error;
                     if (![privateManagedObjectContext save:&error]) {
                         NSLog(@"CoreDataStack -> error saving _privateMOC: %@ %@", [error localizedDescription], [error userInfo]);
                     }
                 }];
             }
         }];
    }
    return privateManagedObjectContext;
}

+ (NSManagedObjectContext *)mainUIManagedObjectContext {
    if (!mainUIManagedObjectContext) {
        
        // Setup MOC attached to parent privateMOC in main queue
        mainUIManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [mainUIManagedObjectContext setParentContext:[self privateManagedObjectContext]];
        
        // Add notification to perform save when the child is updated
        mainUIContextSaveObserver =
        [[NSNotificationCenter defaultCenter]
         addObserverForName:NSManagedObjectContextDidSaveNotification
         object:nil
         queue:nil
         usingBlock:^(NSNotification *note) {
             NSManagedObjectContext *savedContext = [note object];
             if (savedContext.parentContext == mainUIManagedObjectContext) {
                 NSLog(@"CoreDataStack -> saving mainUIMOC");
                 [mainUIManagedObjectContext performBlock:^{
                     NSError *error;
                     if (![mainUIManagedObjectContext save:&error]) {
                         NSLog(@"CoreDataStack -> error saving mainUIMOC: %@ %@", [error localizedDescription], [error userInfo]);
                     }
                 }];
             }
         }];
    }
    return mainUIManagedObjectContext;
}

+ (NSManagedObjectContext *)importManagedObjectContext {
    if (!importManagedObjectContext) {
        
        // Setup MOC attached to parent mainUIMOC in private queue
        importManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [importManagedObjectContext setParentContext:[self mainUIManagedObjectContext]];
    }
    return importManagedObjectContext;
}

@end
