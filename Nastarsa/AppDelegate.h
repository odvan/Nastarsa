//
//  AppDelegate.h
//  Nastarsa
//
//  Created by Artur Kablak on 06/08/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (assign, nonatomic) BOOL shouldRotate;

- (void)saveContext;

@end
