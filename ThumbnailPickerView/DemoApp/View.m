//
//  View.m
//  ThumbnailPickerView
//
//  Created by Dominik Kapusta on 12-01-18.
//  Copyright (c) 2012 Dominik Kapusta.
//

#import "View.h"

@implementation View

@synthesize imageView = _imageView, infoLabel = _infoLabel;

- (void)layoutSubviews
{
//    BOOL landscape = self.bounds.size.width > self.bounds.size.height;
//    
//    if (landscape) {
//        self.infoLabel.frame = CGRectMake(117, 12, 96, 20);
//        self.imageView.frame = CGRectMake(20, 36, 290, 194);
//    } else {
//        self.infoLabel.frame = CGRectMake(112, 180, 96, 20);
//        self.imageView.frame = CGRectMake(15, 208, 290, 194);
//    }
}

@end
