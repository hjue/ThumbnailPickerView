//
//  AppDelegate.m
//  ThumbnailPickerView
//
//  Created by Dominik Kapusta on 12-01-18.
//  Copyright (c) 2012 Dominik Kapusta.
//
//  Latest code can be found on GitHub: https://github.com/ayoy/ThumbnailPickerView
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] init];
    
//    NSArray* paths = [[NSArray alloc] initWithObjects:@"http://farm6.static.flickr.com/5042/5323996646_9c11e1b2f6_b.jpg", @"http://farm6.static.flickr.com/5007/5311573633_3cae940638.jpg",nil];
    NSArray* paths = [[NSArray alloc] initWithObjects:@"http://images13.mdscollections.com/prod_images_small/IMG_85003.JPG",@"http://i618.photobucket.com/albums/tt269/foggiare/Collection110/110-18-S.jpg",@"http://www.ministryofretail.com/images/Korean_Top/T01513hp.jpg",@"http://www.ministryofretail.com/images/Korean_Top/T01509hp.jpg",@"http://cdn.lovebonito.com/1950-21021-home/shelburne-skirt.jpg",@"http://cdn.lovebonito.com/1919-20678-home/tallise-top.jpg",@"http://cdn.lovebonito.com/1889-20346-home/tashe-maxi.jpg",@"http://images12.mdscollections.com/prod_images_small/IMG_85923.JPG",@"http://images12.mdscollections.com/prod_images_small/IMG_85984.JPG",@"http://cdn.lovebonito.com/1917-20641-home/lashore-skater-dress.jpg",nil];
    //NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:paths.count];
    for (NSString *path in paths) {
        //[images addObject:[UIImage imageWithContentsOfFile:path]];
        NSURL * imageURL = [NSURL URLWithString:path];
        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage * image = [UIImage imageWithData:imageData];
        [images addObject:image];
    }
    
    self.viewController.images = images;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
