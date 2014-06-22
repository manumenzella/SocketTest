//
//  ViewController.m
//  Location
//
//  Created by Manuel Menzella on 1/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define DISTANCE_DELEGATE_MIN 200
#define DISTANCE_UPDATE_MIN 200
#define MODE_AUTOMATIC YES

// IF MODE_AUTOMATIC IS SET TO "YES"
#define INTERVAL_BETWEEN_UPDATES_MIN 300
#define INTERVAL_ACCURACY_INCREASE_MAX 10
#define ACCURACY_MIN 120

#import "ViewController.h"
#import "AFNetworking.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) CLLocation *lastSentLocation;

@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic, strong) NSString *dataString;

@property (nonatomic, strong) NSDate *lastSentDate;
@property (nonatomic, strong) NSDate *accuracyIncreaseDate;
@property (nonatomic) BOOL isIncreasingAccuracy;

@property (nonatomic, assign) IBOutlet UISegmentedControl *accuracyControl;
@property (nonatomic, assign) IBOutlet UITextView *locationTextView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.accuracy) self.accuracy = kCLLocationAccuracyKilometer;
    if (MODE_AUTOMATIC) {
        self.accuracyControl.enabled = NO;
        self.accuracyControl.hidden = YES;
    }
    
    int intAccuracy = roundf((float)self.accuracy);
    switch (intAccuracy) {
        case 1000:
            self.accuracyControl.selectedSegmentIndex = 0;
            break;
            
        case 100:
            self.accuracyControl.selectedSegmentIndex = 1;
            break;
            
        case 10:
            self.accuracyControl.selectedSegmentIndex = 2;
            break;
            
        default:
            break;
    }
    
    [self setupLocationTrackingWithAccuracy:self.accuracy andDistanceFilter:DISTANCE_DELEGATE_MIN];
}

- (IBAction)setNewAccuracy:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.accuracy = kCLLocationAccuracyKilometer;
            break;
            
        case 1:
            self.accuracy = kCLLocationAccuracyHundredMeters;
            break;
            
        case 2:
            self.accuracy = kCLLocationAccuracyNearestTenMeters;
            break;
            
        default:
            self.accuracy = kCLLocationAccuracyKilometer;
            break;
    }
    [self setupLocationTrackingWithAccuracy:self.accuracy andDistanceFilter:DISTANCE_DELEGATE_MIN];
}

- (void)setupLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy andDistanceFilter:(float)distanceFilter
{
    [self.locationManager stopUpdatingLocation];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = accuracy;
    self.locationManager.distanceFilter = distanceFilter;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    self.locationTextView.text = location.description;
    NSLog(@"%@", location.description);
    
    // if !lastSentLocation, or location changed significantly
    //if (!self.lastSentLocation || [location distanceFromLocation:self.lastSentLocation] > 50) {
    
    if (!self.lastSentLocation || [location distanceFromLocation:self.lastSentLocation] > DISTANCE_UPDATE_MIN || self.isIncreasingAccuracy)
    {
        
        if (!MODE_AUTOMATIC) {
            if (!self.dataString) self.dataString = [[NSString alloc] init];
            self.dataString = [self.dataString stringByAppendingString:[NSString stringWithFormat:@"distance: %f - set accuracy: %f - %@ - backgroundTimeRemaining: %f\n", [self.lastSentLocation distanceFromLocation:location], [self.locationManager desiredAccuracy], location.description, [[UIApplication sharedApplication] backgroundTimeRemaining]]];
            [self sendStringToServer:self.dataString];
            self.dataString = nil;
            
            self.lastSentLocation = location;
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = [NSString stringWithFormat:@"distance: %.2f  --  background: %s", [self.lastSentLocation distanceFromLocation:location], [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive ? "YES":"NO"];
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
        } else {
            
            if (!self.isIncreasingAccuracy) {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                self.accuracyIncreaseDate = [NSDate date];
                self.isIncreasingAccuracy = YES;
            }
            if (location.horizontalAccuracy <= ACCURACY_MIN || [[NSDate date] timeIntervalSinceDate:self.accuracyIncreaseDate] > INTERVAL_ACCURACY_INCREASE_MAX) {
                
                if (!self.dataString) self.dataString = [[NSString alloc] init];
                self.dataString = [self.dataString stringByAppendingString:[NSString stringWithFormat:@"distance: %f - set accuracy: %f - %@ - backgroundTimeRemaining: %f\n", [self.lastSentLocation distanceFromLocation:location], [self.locationManager desiredAccuracy], location.description, [[UIApplication sharedApplication] backgroundTimeRemaining]]];
                [self sendStringToServer:self.dataString];
                self.dataString = nil;
                
                self.lastSentLocation = location;
                
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertBody = [NSString stringWithFormat:@"distance: %.2f  --  background: %s", [self.lastSentLocation distanceFromLocation:location], [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive ? "YES":"NO"];
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
                self.accuracyIncreaseDate = nil;
                self.isIncreasingAccuracy = NO;
            }
        }
    
    } else {
        
        if (!self.dataString) self.dataString = [[NSString alloc] init];
        self.dataString = [self.dataString stringByAppendingString:[NSString stringWithFormat:@"NOT SENT! || distance: %f - set accuracy: %f - %@ - backgroundTimeRemaining: %f\n", [self.lastSentLocation distanceFromLocation:location], [self.locationManager desiredAccuracy], location.description, [[UIApplication sharedApplication] backgroundTimeRemaining]]];
        
        NSLog(@"UPDATE NOT SENT: distance -> %f", [self.lastSentLocation distanceFromLocation:location]);
    }
    
    // update last location
    self.lastLocation = location;
}

- (void)sendStringToServer:(NSString *)string
{
    NSLog(@"Sending...");
    
    //NSString *urlString = @"http://192.168.1.11:7400/post";
    NSString *urlString = @"http://50.112.249.164:7400/post";
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"data": string};
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)sendLocationToServer:(CLLocation *)location
{
    NSLog(@"Sending...");
    
    NSString *dataString = [NSString stringWithFormat:@"distance: %f - set accuracy: %f - %@ - backgroundTimeRemaining: %f\n", [self.lastLocation distanceFromLocation:location], [self.locationManager desiredAccuracy], location.description, [[UIApplication sharedApplication] backgroundTimeRemaining]];
    
    //NSString *urlString = @"http://192.168.1.11:7400/post";
    NSString *urlString = @"http://50.112.249.164:7400/post";
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"data": dataString};
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
