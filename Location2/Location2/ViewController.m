//
//  ViewController.m
//  Location2
//
//  Created by Manuel Menzella on 1/4/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define DISTANCE_S_VALUE 0.65f
#define DISTANCE_FILTER_STILL 200.0f
#define DISTANCE_FILTER_MOVING 100.0f
#define INTERVAL_LOCATION_UPDATE_TIMER 120.0f
#define INTERVAL_INCREASE_ACCURACY 10.0f
#define LOCATION_ACCURACY_UPDATE 100.0f

#import "ViewController.h"
#import "AFNetworking.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) CLLocation *lastSentLocation;
@property (nonatomic, strong) NSDate *startMovingDate;
@property (nonatomic, strong) NSDate *startIncreasingAccuracyDate;
@property (nonatomic, strong) NSTimer *locationUpdateTimer;
@property (nonatomic) BOOL isMoving;
@property (nonatomic) BOOL isIncreasingAccuracy;

@property (nonatomic, strong) NSString *dataString;

@property (nonatomic, assign) IBOutlet UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataString = [[NSString alloc] init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.distanceFilter = DISTANCE_FILTER_STILL;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    self.textView.text = location.description;
    [self logString:[NSString stringWithFormat:@"LOCATION: %@", location.description] presentLocalNotification:NO];
    
    if (!self.lastSentLocation && !self.isIncreasingAccuracy) {
        self.isIncreasingAccuracy = YES;
        self.startIncreasingAccuracyDate = [NSDate date];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_INCREASE_ACCURACY target:self selector:@selector(locationTimer) userInfo:nil repeats:NO];
        [self logString:@"Increasing accuracy for first location..." presentLocalNotification:NO];
    }
    
    if ( !self.isIncreasingAccuracy && [location distanceFromLocation:self.lastLocation] < (self.isMoving ? DISTANCE_FILTER_MOVING : DISTANCE_FILTER_STILL) ) {
        // Very close location update, and was not caused by accuracy increase. Should return.
        return;
    }
    
    float locationStdDev = location.horizontalAccuracy / 3.00f;
    float s = ([location distanceFromLocation:self.lastSentLocation] - DISTANCE_FILTER_STILL) / locationStdDev;
    
    if (!self.isMoving && s > DISTANCE_S_VALUE && !self.isIncreasingAccuracy) {
        self.isMoving = YES;
        self.startMovingDate = [NSDate date];
        self.locationManager.distanceFilter = DISTANCE_FILTER_MOVING;
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_LOCATION_UPDATE_TIMER target:self selector:@selector(locationTimer) userInfo:nil repeats:NO];
        
        [self sendStringToServer:@"Location INVALID: isMoving = YES"];
        
        [self logString:@"Started moving!" presentLocalNotification:YES];
    }
    
    if (self.isMoving) {
        
        [self.locationUpdateTimer invalidate];
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_LOCATION_UPDATE_TIMER target:self selector:@selector(locationTimer) userInfo:nil repeats:NO];
        
        //if (!self.dataString) self.dataString = [[NSString alloc] init];
        self.dataString = [self.dataString stringByAppendingString:[NSString stringWithFormat:@"distance: %f - %@\n", [location distanceFromLocation:self.lastSentLocation], location.description]];
        
        [self logString:[NSString stringWithFormat:@"Location update; distance from last sent location: %f - accuracy: %f", [location distanceFromLocation:self.lastSentLocation], location.horizontalAccuracy] presentLocalNotification:NO];
    }
    
    //if (!self.lastSentLocation || (self.isIncreasingAccuracy && (location.horizontalAccuracy <= LOCATION_ACCURACY_UPDATE || [[NSDate date] timeIntervalSinceDate:self.startIncreasingAccuracyDate] > INTERVAL_INCREASE_ACCURACY)) ) {
    if ( self.isIncreasingAccuracy && (location.horizontalAccuracy <= LOCATION_ACCURACY_UPDATE || [[NSDate date] timeIntervalSinceDate:self.startIncreasingAccuracyDate] > INTERVAL_INCREASE_ACCURACY) ) {
        
        if (location.horizontalAccuracy <= LOCATION_ACCURACY_UPDATE) [self logString:@"Accuracy achieved!" presentLocalNotification:NO];
        else if ([[NSDate date] timeIntervalSinceDate:self.startIncreasingAccuracyDate] > INTERVAL_INCREASE_ACCURACY) [self logString:@"Accuracy increase timeout!" presentLocalNotification:NO];
        
        if (!self.lastSentLocation) [self logString:@"Is first location!" presentLocalNotification:NO];
        
        //if (self.lastSentLocation && [location distanceFromLocation:self.lastSentLocation] < DISTANCE_FILTER_STILL) {
        //    [self logString:@"Cancelling position update; too close to last sent location." presentLocalNotification:YES];
        //    return;
        //}
        
        [self sendLocationToServer:location];
        
        self.isMoving = NO;
        self.isIncreasingAccuracy = NO;
        self.startMovingDate = nil;
        self.startIncreasingAccuracyDate = nil;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        self.locationManager.distanceFilter = DISTANCE_FILTER_STILL;
        [self.locationUpdateTimer invalidate];
    }
    
    self.lastLocation = location;
}

- (void)locationTimer
{
    if (!self.isIncreasingAccuracy) {
        // Did not move in INTERVAL_LOCATION_UPDATE_TIMER. Start increasing accuracy.
        
        self.isIncreasingAccuracy = YES;
        self.startIncreasingAccuracyDate = [NSDate date];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_INCREASE_ACCURACY target:self selector:@selector(locationTimer) userInfo:nil repeats:NO];
        [self logString:@"Stopped moving. Started increasing accuracy..." presentLocalNotification:YES];
        
    } else {
        // Did not reach increased accuracy in INTERVAL_INCREASE_ACCURACY. Send last location.
        
        [self sendLocationToServer:self.lastLocation];
        
        self.isMoving = NO;
        self.isIncreasingAccuracy = NO;
        self.startMovingDate = nil;
        self.startIncreasingAccuracyDate = nil;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        self.locationManager.distanceFilter = DISTANCE_FILTER_STILL;
        [self.locationUpdateTimer invalidate];
        
        [self logString:@"No increase in accuracy... Sending last location" presentLocalNotification:NO];
    }
}

- (void)sendLocationToServer:(CLLocation *)location
{
    [self logString:[NSString stringWithFormat:@"Sending; distance from last sent location: %f - accuracy: %f", [location distanceFromLocation:self.lastSentLocation], location.horizontalAccuracy] presentLocalNotification:YES];
    [self logString:[NSString stringWithFormat:@"Accuracy: %f", location.horizontalAccuracy] presentLocalNotification:NO];
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
    
    self.dataString = [self.dataString stringByAppendingString:[NSString stringWithFormat:@"SENT batt: %f - distance: %f - %@\n", batteryLevel, [location distanceFromLocation:self.lastSentLocation], location.description]];
    [self sendStringToServer:self.dataString];
    self.lastSentLocation = location;
    
    self.dataString = [[NSString alloc] init];
}

- (void)sendStringToServer:(NSString *)string
{
    //NSString *urlString = @"http://localhost:7400/post";
    NSString *urlString = @"http://50.112.249.164:7400/post";
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"data": string};
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Successfully sent to server!");
        [self logString:@"Successfully sent to server!" presentLocalNotification:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)logString:(NSString *)string presentLocalNotification:(BOOL)presentLocalNotification
{
    NSLog(@"%@", string);
    if (presentLocalNotification) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = string;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

@end
