//
//  TypeView.h
//  Slider
//
//  Created by Manuel Menzella on 12/30/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@interface TypeView : UIView

@property (nonatomic, retain) IBOutlet HPGrowingTextView *growingTextView;
@property (nonatomic, retain) IBOutlet UIButton *sendButton;

@end
