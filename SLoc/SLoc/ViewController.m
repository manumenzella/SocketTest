//
//  ViewController.m
//  SLoc
//
//  Created by Manuel Menzella on 1/6/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define ACCURACY_REQUIRED 100.0f
#define ACCURACY_TIMEOUT 60.0f

#import "ViewController.h"
#import "AFNetworking.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, assign) IBOutlet UISwitch *locationToggle;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDate *accuracyIncreaseStartDate;
@property (nonatomic) BOOL isIncreasingAccuracy;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	   
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.distanceFilter = 0;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    if (self.locationToggle.isOn) [self.locationManager startMonitoringSignificantLocationChanges];
    else [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (IBAction)locationToggleDidChangeValue:(id)sender
{
    if (self.locationToggle.isOn) [self.locationManager startMonitoringSignificantLocationChanges];
    else [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    if (!self.isIncreasingAccuracy) {
        self.isIncreasingAccuracy = YES;
        self.accuracyIncreaseStartDate = [NSDate date];
        if (location.horizontalAccuracy >= ACCURACY_REQUIRED) {
            [self.locationManager startUpdatingLocation];
            [self logString:@"LOCATION MANAGER startUpdatingLocation"];
            [self logString:[NSString stringWithFormat:@"Starting accuracy increase; accuracy: %f  ||  %@", location.horizontalAccuracy, location.description]];
        } else {
            [self logString:@"Location already high precision"];
        }
    }
    
    if (self.isIncreasingAccuracy && (location.horizontalAccuracy <= ACCURACY_REQUIRED || [[NSDate date] timeIntervalSinceDate:self.accuracyIncreaseStartDate] > ACCURACY_TIMEOUT)) {
        self.isIncreasingAccuracy = NO;
        self.accuracyIncreaseStartDate = nil;
        [self.locationManager stopUpdatingLocation];
        [self logString:@"LOCATION MANAGER stopUpdatingLocation"];
        
        [self logString:[NSString stringWithFormat:@"SENT Update; accuracy: %f  ||  %@", location.horizontalAccuracy, location.description]];
    }
}

- (void)logString:(NSString *)string
{
    NSLog(@"%@", string);
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = string;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    
    [self sendStringToServer:[NSString stringWithFormat:@"%@\n", string]];
}

- (void)sendStringToServer:(NSString *)string
{
    //NSString *urlString = @"http://localhost:7400/post";
    NSString *urlString = @"http://50.112.249.164:7400/post";
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"data": string};
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully sent to server!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
