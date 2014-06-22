//
//  TypeView.m
//  Slider
//
//  Created by Manuel Menzella on 12/30/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#define SEND_BUTTON_HEIGHT
#define SEND_BUTTON WIDTH
#

#import "TypeView.h"

@implementation TypeView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.backgroundColor = [UIColor lightGrayColor];
    self.growingTextView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(10, 10, 160, 40)];
    [self addSubview:self.growingTextView];
}

@end
