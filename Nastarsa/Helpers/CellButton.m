//
//  CellButton.m
//  Nastarsa
//
//  Created by Artur Kablak on 09/12/2017.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

#import "CellButton.h"

@implementation CellButton

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.highlighted = true;
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.highlighted = false;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.highlighted = false;
    [super touchesCancelled:touches withEvent:event];
}

@end
