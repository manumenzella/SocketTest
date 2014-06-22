//
//  UIImage+Tools.h
//  VideoPreview
//
//  Created by Manuel Menzella on 12/28/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//



@interface UIImage (Tools)

- (UIImage *)squareCenterImage;
- (UIImage *)scaledCopyOfSize:(CGSize)newSize andOrientation:(UIImageOrientation)orient;

@end
