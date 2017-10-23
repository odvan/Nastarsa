//
//  CoreDataStack.h
//  Nastarsa
//
//  Created by Artur Kablak on 22/10/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"



@interface CoreDataStack : NSObject

+ (NSManagedObjectContext *)privateManagedObjectContext;
+ (NSManagedObjectContext *)mainUIManagedObjectContext;
+ (NSManagedObjectContext *)importManagedObjectContext;

@end
