//
//  ViewController.m
//  VideoPreview
//
//  Created by Manuel Menzella on 12/26/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#define ANIMATION_DURATION 0.30f

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "ViewController.h"
#import "UIButton+Bootstrap.h"
#import "UIImage+Tools.h"
#import "AFNetworking.h"
#import "TWMessageBarManager.h"

@interface ViewController ()

@property BOOL frontFacing;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDeviceBack;
@property (nonatomic, strong) AVCaptureDevice *captureDeviceFront;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"VideoPreview";
    self.previewView.alpha = 0.00f;
    [self.switchCameraButton dangerStyle];
    [self.takePhotoButton successStyle];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.previewView addGestureRecognizer:tapGestureRecognizer];
    
    [self configureVideoPreview];
}

- (void)configureVideoPreview
{
    [self.captureSession stopRunning];
    self.captureSession = [[AVCaptureSession alloc] init];
    
    NSArray *captureDevices = [AVCaptureDevice devices];
    for (AVCaptureDevice *captureDevice in captureDevices) {
        if ([captureDevice hasMediaType:AVMediaTypeVideo]) {
            if (captureDevice.position == AVCaptureDevicePositionBack) {
                self.captureDeviceBack = captureDevice;
            } else {
                self.captureDeviceFront = captureDevice;
            }
        }
    }
    
    if (!self.frontFacing) {
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDeviceBack error:nil];
    } else {
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDeviceFront error:nil];
    }
    if ([self.captureSession canAddInput:self.captureDeviceInput]) [self.captureSession addInput:self.captureDeviceInput];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.videoPreviewLayer.frame = self.previewView.bounds;
    [self.previewView.layer addSublayer:self.videoPreviewLayer];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
        [self.stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    }
    
    [self.captureSession startRunning];
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{ self.previewView.alpha = 1.00f; }];
}

- (void)tap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self.previewView];
    CGPoint pointOfInterest = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:tapLocation];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:pointOfInterest monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		AVCaptureDevice *captureDevice = self.captureDeviceInput.device;
		NSError *error = nil;
		if ([captureDevice lockForConfiguration:&error])
		{
			if ([captureDevice isFocusPointOfInterestSupported] && [captureDevice isFocusModeSupported:focusMode])
			{
				[captureDevice setFocusMode:focusMode];
				[captureDevice setFocusPointOfInterest:point];
			}
			if ([captureDevice isExposurePointOfInterestSupported] && [captureDevice isExposureModeSupported:exposureMode])
			{
				[captureDevice setExposureMode:exposureMode];
				[captureDevice setExposurePointOfInterest:point];
			}
			[captureDevice setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[captureDevice unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(0.5, 0.5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (IBAction)snapStillImage:(id)sender
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImageOrientation orientation = currentImageOrientation((self.captureDeviceInput.device.position == AVCaptureDevicePositionFront), NO);
        
		// Flash set to Auto for Still Capture
		[ViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[self.captureDeviceInput device]];
		
		// Capture a still image.
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			
			if (imageDataSampleBuffer)
			{
				NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
				UIImage *image = [[UIImage alloc] initWithData:imageData];
                
                //UIImage *normalizedImage = [[image squareCenterImage] scaledCopyOfSize:CGSizeMake(800.0f, 800.0f) andOrientation:orientation];
                //NSLog(@"%@", imageOrientationNameFromOrientation(orientation));
                
                // With effect
                UIImage *normalizedImage = [self imageWithEffect:[[image squareCenterImage] scaledCopyOfSize:CGSizeMake(800.0f, 800.0f) andOrientation:orientation]];
                NSLog(@"%@", imageOrientationNameFromOrientation(orientation));
                
                UIImageView *imageView = [[UIImageView alloc] initWithImage:normalizedImage];
                imageView.frame = self.previewView.frame;
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.clipsToBounds = YES;
                [self.view addSubview:imageView];
                [UIView animateWithDuration:0.3f delay:2.0f options:0 animations:^{ imageView.alpha = 0.00f; } completion:^(BOOL finished){ [imageView removeFromSuperview]; }];
                
                //[self uploadImage:[image squareCenterImage] withSize:CGSizeMake(800.0f, 800.0f) andJPEGCompressionQuality:0.50f];
                [self uploadImage:[self imageWithEffect:[image squareCenterImage]] withSize:CGSizeMake(800.0f, 800.0f) andJPEGCompressionQuality:0.50];
			}
		}];
	});
}

UIImageOrientation currentImageOrientationWithMirroring(BOOL isUsingFrontCamera)
{
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            return isUsingFrontCamera ? UIImageOrientationRight : UIImageOrientationLeftMirrored;
        case UIDeviceOrientationPortraitUpsideDown:
            return isUsingFrontCamera ? UIImageOrientationLeft :UIImageOrientationRightMirrored;
        case UIDeviceOrientationLandscapeLeft:
            return isUsingFrontCamera ? UIImageOrientationDown :  UIImageOrientationUpMirrored;
        case UIDeviceOrientationLandscapeRight:
            return isUsingFrontCamera ? UIImageOrientationUp : UIImageOrientationDownMirrored;
        default:
            //return  UIImageOrientationUp;
            return isUsingFrontCamera ? UIImageOrientationRight : UIImageOrientationLeftMirrored;
    }
}

// Expected Image orientation from current orientation and camera in use
UIImageOrientation currentImageOrientation(BOOL isUsingFrontCamera, BOOL shouldMirrorFlip)
{
    if (shouldMirrorFlip)
        return currentImageOrientationWithMirroring(isUsingFrontCamera);
        
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            return isUsingFrontCamera ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
        case UIDeviceOrientationPortraitUpsideDown:
            return isUsingFrontCamera ? UIImageOrientationRightMirrored :UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeLeft:
            return isUsingFrontCamera ? UIImageOrientationDownMirrored :  UIImageOrientationUp;
        case UIDeviceOrientationLandscapeRight:
            return isUsingFrontCamera ? UIImageOrientationUpMirrored :UIImageOrientationDown;
        default:
            //return  UIImageOrientationUp;
            return isUsingFrontCamera ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
    }
}

NSString *imageOrientationNameFromOrientation(UIImageOrientation orientation)
{
    NSArray *names = [NSArray
                      arrayWithObjects:
                      @"Up",
                      @"Down",
                      @"Left",
                      @"Right",
                      @"Up-Mirrored",
                      @"Down-Mirrored",
                      @"Left-Mirrored",
                      @"Right-Mirrored",
                      nil];
    return [names objectAtIndex:orientation];
}

- (void)uploadImage:(UIImage *)image withSize:(CGSize)size andJPEGCompressionQuality:(float)quality
{
    if (!image) return;
    
    //UIImage *resizedImage = [image resizedImage:CGSizeMake(800.0f, 800.0f) interpolationQuality:kCGInterpolationHigh];
    //UIImage *resizedImage = [self imageByScalingAndCropping:image forSize:size];
    
    UIImage *resizedImage = [image scaledCopyOfSize:size andOrientation:currentImageOrientation(NO, NO)];
    
    NSData *imageJPEGData = UIImageJPEGRepresentation(resizedImage, quality);
    NSLog(@"%.2f kB", [imageJPEGData length] / 1024.0f);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"foo": @"bar"};
    //NSString *urlString = @"http://192.168.1.11:8080/upload";
    NSString *urlString = @"http://50.112.249.164:8080/upload";
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [manager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageJPEGData name:@"image" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Success!" description:@"The image was uploaded to the server." type:TWMessageBarMessageTypeInfo];
        NSLog(@"Success: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Error" description:@"The image was not uploaded." type:TWMessageBarMessageTypeError];
        NSLog(@"Error: %@", error);
    }];
}

- (UIImage *)imageWithEffect:(UIImage *)orgImage
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:orgImage];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
    [filter setDefaults];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    
    CGImageRelease(cgImage);
    
    return image;
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

- (IBAction)switchCamera:(id)sender
{
    self.frontFacing = !self.frontFacing;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{ self.previewView.alpha = 0.00f; } completion:^(BOOL finished){ [self configureVideoPreview]; }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self captureDeviceInput] device]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self captureDeviceInput] device]];
}

@end
