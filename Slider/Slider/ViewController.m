//
//  ViewController.m
//  Slider
//
//  Created by Manuel Menzella on 12/30/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import "ViewController.h"
#import "TypeView.h"

@interface ViewController () <HPGrowingTextViewDelegate>
@property (nonatomic, assign) IBOutlet TypeView *typeView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.typeView.growingTextView.isScrollable = NO;
    self.typeView.growingTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
	self.typeView.growingTextView.minNumberOfLines = 1;
	self.typeView.growingTextView.maxNumberOfLines = 6;
    // you can also set the maximum height in points with maxHeight
    // textView.maxHeight = 200.0f;
	self.typeView.growingTextView.returnKeyType = UIReturnKeyGo; //just as an example
	self.typeView.growingTextView.font = [UIFont systemFontOfSize:15.0f];
	self.typeView.growingTextView.delegate = self;
    self.typeView.growingTextView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    self.typeView.growingTextView.backgroundColor = [UIColor whiteColor];
    self.typeView.growingTextView.placeholder = @"Type to see the textView grow!";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.typeView.frame = CGRectOffset(self.typeView.frame, 0.00f, -keyboardFrame.size.height);
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    self.typeView.frame = CGRectOffset(self.typeView.frame, 0.00f, keyboardFrame.size.height);
    
    [UIView commitAnimations];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    NSLog(@"%f", diff);
    
	CGRect r = self.typeView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.typeView.frame = r;
}

@end
