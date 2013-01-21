//
//  ThumbnailPickerView.m
//  ThumbnailPickerView
//
//  Created by Dominik Kapusta on 11-12-20.
//  Copyright (c) 2011 Dominik Kapusta.
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

#warning TODO: ThumbnailView增加ScrollBar


#import "ThumbnailPickerView.h"

static const CGSize kThumbnailSize        = {16, 13};
static const CGSize kBigThumbnailSize     = {36, 27};
static const NSUInteger kThumbnailSpacing = 1;

static const NSUInteger kTagOffset = 100;
static const NSUInteger kBigThumbnailTagOffset = 1000;

@interface ThumbnailPickerView()
- (UIImageView *)_createThumbnailImageViewWithSize:(CGSize)size;
- (void)_setup;
- (void)_updateSelectedIndexForTouch:(UITouch *)touch fineGrained:(BOOL)fineGrained;
- (void)_updateBigThumbnailPositionVerbose:(BOOL)verbose animated:(BOOL)animated;
- (void)_memoryWarning:(NSNotification *)notification;

- (void)_prepareImageViewForReuse:(UIImageView *)imageView;
- (UIImageView *)_dequeueReusableImageView;

@property (nonatomic, assign) NSUInteger visibleThumbnailsCount;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) UIImageView *bigThumbnailImageView;
@property (nonatomic, strong, readonly) NSMutableSet *reusableThumbnailImageViews;
@end
 
@implementation ThumbnailPickerView

@synthesize selectedIndex = _selectedIndex;
@synthesize dataSource = _dataSource, delegate = _delegate;
@synthesize visibleThumbnailsCount = _visibleThumbnailsCount;
@synthesize contentView = _contentView, bigThumbnailImageView = _bigThumbnailImageView;
@synthesize reusableThumbnailImageViews = _reusableThumbnailImageViews;
@synthesize isVertical = _isVertical;
@synthesize thumbnailSize = _thumbnailSize;
@synthesize bigThumbnailSize = _bigThumbnailSize;

- (UIImageView *)_createThumbnailImageViewWithSize:(CGSize)size
{

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.backgroundColor = [UIColor grayColor];
    imageView.layer.borderWidth = 1;
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = NO;
    return imageView;
}

- (void)_setup
{
    self.selectedIndex = NSNotFound;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)_memoryWarning:(NSNotification *)notification
{
    [self.reusableThumbnailImageViews removeAllObjects];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated
{
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;
        if (_selectedIndex != NSNotFound)
            [self _updateBigThumbnailPositionVerbose:NO animated:animated];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (NSMutableSet *)reusableThumbnailImageViews
{
    if (!_reusableThumbnailImageViews) {
        _reusableThumbnailImageViews = [NSMutableSet set];
    }
    return _reusableThumbnailImageViews;
}

- (UIImageView *)_dequeueReusableImageView
{
    UIImageView *imageView = [self.reusableThumbnailImageViews anyObject];
    
    if (imageView) {
        [self.reusableThumbnailImageViews removeObject:imageView];
//        NSLog(@"found reusable image view!");
    }

    return imageView;
}

- (void)_prepareImageViewForReuse:(UIImageView *)imageView
{
    if (imageView.tag != 0) {
        imageView.image = nil;
        imageView.tag = 0;
        [self.reusableThumbnailImageViews addObject:imageView];
        [imageView removeFromSuperview];
    }
}

- (void)setDataSource:(id<ThumbnailPickerViewDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self setNeedsLayout]; // layoutSubviews calls reloadData
    }
}

- (void)reloadData
{
    NSUInteger totalItemsCount = [self.dataSource numberOfImagesForThumbnailPickerView:self];
    if (totalItemsCount == 0)
        return;
    
    if (self.isVertical)
    {
        // calculate number of thumbnail visible
        CGFloat contentsHeight = totalItemsCount * self.thumbnailSize.height + (totalItemsCount-1) * kThumbnailSpacing; // cw = i*w + (i-1)*s
        if (contentsHeight > self.bounds.size.height) {
            self.visibleThumbnailsCount = floor((self.bounds.size.height+kThumbnailSpacing)/(self.thumbnailSize.height+kThumbnailSpacing)); // i = (c+s)/(w+s)
//            NSLog(@"items count: %d, new items count: %d, width: %.0f", totalItemsCount, self.visibleThumbnailsCount, self.bounds.size.width);
            contentsHeight = self.visibleThumbnailsCount * self.thumbnailSize.height + (self.visibleThumbnailsCount-1) * kThumbnailSpacing;
        } else {
            self.visibleThumbnailsCount = totalItemsCount;
        }
        
        NSMutableArray *indices = [NSMutableArray arrayWithCapacity:self.visibleThumbnailsCount];
        if (self.visibleThumbnailsCount < totalItemsCount) {
            for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
                [indices addObject:[NSNumber numberWithUnsignedInteger:(float)i/(self.visibleThumbnailsCount-1)*(totalItemsCount-1)]];
            }
        } else {
            for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
                [indices addObject:[NSNumber numberWithUnsignedInteger:i]];
            }
        }
        
        // set up the content view size
        if (!self.contentView) {
            self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.thumbnailSize.width, contentsHeight)];
            self.contentView.userInteractionEnabled = NO;
            self.contentView.backgroundColor = [UIColor clearColor];
            [self addSubview:self.contentView];
        } else {
            
            [self.contentView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (![indices containsObject:[NSNumber numberWithInt:[obj tag]-kTagOffset]]) {
                    [self _prepareImageViewForReuse:obj];
                }
            }];
            
            CGRect contentViewFrame = self.contentView.frame;
            contentViewFrame.size.height = contentsHeight;
            self.contentView.frame = CGRectMake(0, 0, self.thumbnailSize.width, contentsHeight);
        }

        // add thumbnail
        UIImageView *imageView = nil;
        CGRect imageViewFrame;
        NSUInteger index;
        NSInteger tag;
        
        for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
            index = [[indices objectAtIndex:i] unsignedIntegerValue];
            tag = index + kTagOffset;
            
            imageView = (UIImageView *)[self.contentView viewWithTag:tag];
            if (!imageView) {
                imageView = [self _dequeueReusableImageView];
                if (!imageView) {
                    imageView = [self _createThumbnailImageViewWithSize:self.thumbnailSize];
                }
                imageView.tag = tag;
            }
            
            // set position
            imageViewFrame = imageView.frame;
            imageViewFrame.origin.y = i * (self.thumbnailSize.height + kThumbnailSpacing);
            imageViewFrame.origin.x = 0;
            imageView.frame = imageViewFrame;
            
            [self.contentView addSubview:imageView];
            
            //这里采用异步加载image
            dispatch_queue_t imageLoadingQueue = dispatch_queue_create("image loading queue", NULL);
            dispatch_async(imageLoadingQueue, ^{
                UIImage *image = [self.dataSource thumbnailPickerView:self imageAtIndex:index];
                dispatch_async(dispatch_get_main_queue(),^{
                    imageView.image = image;
                });
            });
            dispatch_release(imageLoadingQueue);
        }
    }
    else { // horizontal
    
        CGFloat contentsWidth = totalItemsCount * self.thumbnailSize.width + (totalItemsCount-1) * kThumbnailSpacing; // cw = i*w + (i-1)*s
        if (contentsWidth > self.bounds.size.width) {
            self.visibleThumbnailsCount = floor((self.bounds.size.width+kThumbnailSpacing)/(self.thumbnailSize.width+kThumbnailSpacing)); // i = (c+s)/(w+s)
//            NSLog(@"items count: %d, new items count: %d, width: %.0f", totalItemsCount, self.visibleThumbnailsCount, self.bounds.size.width);
            contentsWidth = self.visibleThumbnailsCount * self.thumbnailSize.width + (self.visibleThumbnailsCount-1) * kThumbnailSpacing;
        } else {
            self.visibleThumbnailsCount = totalItemsCount;
        }
        
        NSMutableArray *indices = [NSMutableArray arrayWithCapacity:self.visibleThumbnailsCount];
        if (self.visibleThumbnailsCount < totalItemsCount) {
            for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
                [indices addObject:[NSNumber numberWithUnsignedInteger:(float)i/(self.visibleThumbnailsCount-1)*(totalItemsCount-1)]];
            }
        } else {
            for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
                [indices addObject:[NSNumber numberWithUnsignedInteger:i]];
            }
        }
        
        if (!self.contentView) {
            self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentsWidth, self.thumbnailSize.height)];
            self.contentView.userInteractionEnabled = NO;
            self.contentView.backgroundColor = [UIColor clearColor];
            [self addSubview:self.contentView];
        } else {
            
            [self.contentView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (![indices containsObject:[NSNumber numberWithInt:[obj tag]-kTagOffset]]) {
                    [self _prepareImageViewForReuse:obj];
                }
            }];
            
            CGRect contentViewFrame = self.contentView.frame;
            contentViewFrame.size.width = contentsWidth;
            self.contentView.frame = CGRectMake(0, 0, contentsWidth, self.thumbnailSize.height);
        }
        
        UIImageView *imageView = nil;
        CGRect imageViewFrame;
        NSUInteger index;
        NSInteger tag;
        
        for (NSUInteger i = 0; i < self.visibleThumbnailsCount; i++) {
            index = [[indices objectAtIndex:i] unsignedIntegerValue];
            tag = index + kTagOffset;
            
            imageView = (UIImageView *)[self.contentView viewWithTag:tag];
            if (!imageView) {
                imageView = [self _dequeueReusableImageView];
                if (!imageView) {
                    imageView = [self _createThumbnailImageViewWithSize:self.thumbnailSize];
                }
                imageView.tag = tag;
            }
            
            imageViewFrame = imageView.frame;
            imageViewFrame.origin.x = i * (self.thumbnailSize.width + kThumbnailSpacing);
            imageViewFrame.origin.y = 0;
            imageView.frame = imageViewFrame;
            
            [self.contentView addSubview:imageView];

            //这里采用异步加载image
            dispatch_queue_t imageLoadingQueue = dispatch_queue_create("image loading queue", NULL);
            dispatch_async(imageLoadingQueue, ^{
                UIImage *image = [self.dataSource thumbnailPickerView:self imageAtIndex:index];
                dispatch_async(dispatch_get_main_queue(),^{
                    imageView.image = image;
                });
            });
            dispatch_release(imageLoadingQueue);
        }
    }
    [self _updateBigThumbnailPositionVerbose:NO animated:NO];
}

- (void)reloadThumbnailAtIndex:(NSUInteger)index
{
    UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:index + kTagOffset];
    if (imageView) {
        dispatch_queue_t imageLoadingQueue = dispatch_queue_create("image loading queue", NULL);
        dispatch_async(imageLoadingQueue, ^{
            UIImage *image = [self.dataSource thumbnailPickerView:self imageAtIndex:index];
            dispatch_async(dispatch_get_main_queue(),^{
                imageView.image = image;
                if (index == self.selectedIndex) {
                    self.bigThumbnailImageView.image = image;
                }
            });
        });
        dispatch_release(imageLoadingQueue);
    }
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self _updateSelectedIndexForTouch:touch fineGrained:NO];
    [self _updateBigThumbnailPositionVerbose:YES animated:NO];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self _updateSelectedIndexForTouch:touch fineGrained:YES];
    [self _updateBigThumbnailPositionVerbose:YES animated:NO];
    return YES;
}

- (void)_updateSelectedIndexForTouch:(UITouch *)touch fineGrained:(BOOL)fineGrained
{
    CGPoint pos = [touch locationInView:self.contentView];
    NSUInteger totalItemsCount = [self.dataSource numberOfImagesForThumbnailPickerView:self];
    NSInteger idx;
    
    if (self.isVertical) // vertical
    {
        if (fineGrained)
            idx = floor(pos.y / self.contentView.frame.size.height * (totalItemsCount-1));
        else
            idx = floor(floor(pos.y/(self.thumbnailSize.height+kThumbnailSpacing)) / (self.visibleThumbnailsCount-1) * (totalItemsCount-1));
    }
    else // horizontal
    {
        if (fineGrained)
            idx = floor(pos.x / self.contentView.frame.size.width * (totalItemsCount-1));
        else
            idx = floor(floor(pos.x/(self.thumbnailSize.width+kThumbnailSpacing)) / (self.visibleThumbnailsCount-1) * (totalItemsCount-1));
    }

    idx = MAX(0, idx);
    idx = MIN(totalItemsCount-1, idx);

    _selectedIndex = idx;
}

- (void)_updateBigThumbnailPositionVerbose:(BOOL)verbose animated:(BOOL)animated
{

    if (self.selectedIndex != NSNotFound && self.contentView.subviews.count > 0) {
        UIView *subview = nil;
        NSInteger tag = self.selectedIndex+kTagOffset;
        NSInteger tagOffset = 0;
//        NSLog(@"trying tag %d, tagOffset %d", tag, tagOffset);
        while (!(subview = [self.contentView viewWithTag:tag])) {
            tag += (tagOffset = (tagOffset + (tagOffset>0 ? 1 : -1)) * -1); // 0, 1, -2, 3, -4, 5, -6 ...
//            NSLog(@"trying tag %d, tagOffset %d", tag, tagOffset);
        }
        
        if (!self.bigThumbnailImageView) {
            UIImageView *bigThumb = [self _createThumbnailImageViewWithSize:self.bigThumbnailSize];
            self.bigThumbnailImageView = bigThumb;
            [self addSubview:self.bigThumbnailImageView];
        }

        void (^animations)(void) = ^ {
            self.bigThumbnailImageView.center = [self.contentView convertPoint:subview.center toView:self];
            dispatch_queue_t imageLoadingQueue = dispatch_queue_create("image loading queue", NULL);
            dispatch_async(imageLoadingQueue, ^{
                UIImage *image = [self.dataSource thumbnailPickerView:self imageAtIndex:self.selectedIndex];
                dispatch_async(dispatch_get_main_queue(),^{
                    self.bigThumbnailImageView.image = image;
                });
            });
            dispatch_release(imageLoadingQueue);
        };

        if (CGSizeEqualToSize(self.bigThumbnailSize, self.thumbnailSize))
        {
            self.bigThumbnailImageView.hidden = YES;
        }else{
            self.bigThumbnailImageView.hidden = NO;
            if (animated)
                [UIView animateWithDuration:0.2 animations:animations];
            else
                animations();
            
            self.bigThumbnailImageView.tag = tag-kTagOffset+kBigThumbnailTagOffset;
            [self bringSubviewToFront:self.bigThumbnailImageView];
        }

        
        if (verbose && [self.delegate respondsToSelector:@selector(thumbnailPickerView:didSelectImageWithIndex:)])
            [self.delegate thumbnailPickerView:self didSelectImageWithIndex:self.selectedIndex];
    }
}

- (void)layoutSubviews
{
    [self reloadData];
//    self.contentView.center = [self convertPoint:self.center fromView:self.superview];
    self.contentView.center = CGPointMake(self.bounds.size.width/2,self.bounds.size.height/2);
    if (self.bigThumbnailImageView) {
        CGRect frame = self.bigThumbnailImageView.frame;
        if (self.isVertical)
        {
            // center big thumbnail view horizontally
            frame.origin.x = (self.bounds.size.width - frame.size.width) * 0.5f;
        }
        else
        {
            // center big thumbnail view vertically
            frame.origin.y = (self.bounds.size.height - frame.size.height) * 0.5f;
        }
        self.bigThumbnailImageView.frame = frame;

        UIView *subview = [self.contentView viewWithTag:self.bigThumbnailImageView.tag-kBigThumbnailTagOffset+kTagOffset];
        if (subview)
            self.bigThumbnailImageView.center = [self.contentView convertPoint:subview.center toView:self];
    }
}

- (CGSize )thumbnailSize
{
    if (_thumbnailSize.width==0) {
        return kThumbnailSize;
    }else
    {
        return _thumbnailSize;
    }
}

- (CGSize) bigThumbnailSize
{
    if (_bigThumbnailSize.width ==0 )
        _bigThumbnailSize = kBigThumbnailSize;

    if (_bigThumbnailSize.width <= _thumbnailSize.width || _bigThumbnailSize.height <= _thumbnailSize.height )
    {
        return _thumbnailSize;
    }else
    {
        return _bigThumbnailSize;        
    }

}
@end
