//
//  ViewController.h
//  VideoPreview
//
//  Created by Manuel Menzella on 12/26/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIView *previewView;
@property (nonatomic, strong) IBOutlet UIButton *switchCameraButton;
@property (nonatomic, strong) IBOutlet UIButton *takePhotoButton;

@end
