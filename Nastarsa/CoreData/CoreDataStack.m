//
//  CoreDataStack.m
//  Nastarsa
//
//  Created by Artur Kablak on 22/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "CoreDataStack.h"

NSManagedObjectContext *_privateManagedObjectContext;
NSManagedObjectContext *_mainUIManagedObjectContext;
NSManagedObjectContext *_importManagedObjectContext;

id privateContextSaveObserver;
id mainUIContextSaveObserver;

@implementation CoreDataStack

#pragma mark - NSManagedObjectContexts

+ (NSManagedObjectContext *)privateManagedObjectContext {
    if (!_privateManagedObjectContext) {
        
        // Setup MOC attached to PSC
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        _privateManagedObjectContext = appDelegate.persistentContainer.newBackgroundContext;
        
        // Add notification to perform save when the child is updated
//        privateContextSaveObserver =
//        [[NSNotificationCenter defaultCenter]
//         addObserverForName:NSManagedObjectContextDidSaveNotification
//         object:nil
//         queue:nil
//         usingBlock:^(NSNotification *note) {
//             NSManagedObjectContext *savedContext = [note object];
//             if (savedContext.parentContext == _privateManagedObjectContext) {
//                 [_privateManagedObjectContext performBlock:^{
//                     NSLog(@"CoreDataStack -> saving privateMOC");
//                     NSError *error;
//                     if (![_privateManagedObjectContext save:&error]) {
//                         NSLog(@"CoreDataStack -> error saving _privateMOC: %@ %@", [error localizedDescription], [error userInfo]);
//                     }
//                 }];
//             }
//         }];
    }
    return _privateManagedObjectContext;
}

+ (NSManagedObjectContext *)mainUIManagedObjectContext {
    if (!_mainUIManagedObjectContext) {
        
        // Setup MOC attached to parent privateMOC in main queue
        _mainUIManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainUIManagedObjectContext setParentContext:[self privateManagedObjectContext]];
        
        // Add notification to perform save when the child is updated
//        mainUIContextSaveObserver =
//        [[NSNotificationCenter defaultCenter]
//         addObserverForName:NSManagedObjectContextDidSaveNotification
//         object:nil
//         queue:nil
//         usingBlock:^(NSNotification *note) {
//             NSManagedObjectContext *savedContext = [note object];
//             if (savedContext.parentContext == mainUIManagedObjectContext) {
//                 NSLog(@"CoreDataStack -> saving mainUIMOC");
//                 [mainUIManagedObjectContext performBlock:^{
//                     NSError *error;
//                     if (![mainUIManagedObjectContext save:&error]) {
//                         NSLog(@"CoreDataStack -> error saving mainUIMOC: %@ %@", [error localizedDescription], [error userInfo]);
//                     }
//                 }];
//             }
//         }];
    }
    return _mainUIManagedObjectContext;
}

+ (NSManagedObjectContext *)importManagedObjectContext {
    if (!_importManagedObjectContext) {
        
        // Setup MOC attached to parent mainUIMOC in private queue
        _importManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_importManagedObjectContext setParentContext:[self mainUIManagedObjectContext]];
    }
    return _importManagedObjectContext;
}

@end
