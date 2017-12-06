//
//  NastarsaCollectionVC+AddAlert.m
//  Nastarsa
//
//  Created by Artur Kablak on 06/12/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "NastarsaCollectionVC+AddAlert.h"

@implementation NastarsaCollectionVC (AddAlert)

// Displaying alert message when error occured

- (void)showAlertWith:(NSString *)title message:(NSString *)message {
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Button
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    [self dismissViewControllerAnimated:YES
                                                             completion:nil];
                                }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
