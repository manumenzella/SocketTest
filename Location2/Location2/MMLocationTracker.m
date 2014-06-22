//
//  MMLocationTracker.m
//  Location2
//
//  Created by Manuel Menzella on 1/6/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#import "MMLocationTracker.h"

#define DEFAULT_DISTANCE_FILTER_STILL_S_VALUE 0.60f
#define DEFAULT_DISTANCE_FILTER_STILL 200.0f
#define DEFAULT_DISTANCE_FILTER_MOVING 100.0f
#define DEFAULT_INTERVAL_STILL_LOCATION_UPDATE 120.0f
#define DEFAULT_INTERVAL_ACCURACY_INCREASE 20.0f
#define DEFAULT_LOCATION_UPDATE_DESIRED_ACCURACY 100.0f


// Accuracy Keys:
// Key 0 -> kCLLocationAccuracyBestForNavigation;
// Key 1 -> kCLLocationAccuracyBest;
// Key 2 -> kCLLocationAccuracyNearestTenMeters;
// Key 3 -> kCLLocationAccuracyHundredMeters;
// Key 4 -> kCLLocationAccuracyKilometer;
// Key 5 -> kCLLocationAccuracyThreeKilometers;
#define ACCURACY_LOW_KEY 5
#define ACCURACY_HIGH_KEY 3

@interface MMLocationTracker () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) CLLocation *lastUpdatedLocation;
@property (nonatomic, strong) NSDate *startMovingDate;
@property (nonatomic, strong) NSDate *startAccuracyIncreaseDate;
@property (nonatomic, strong) NSTimer *locationStillTimer;
@property (nonatomic, strong) NSTimer *accuracyIncreaseTimer;
@property (nonatomic) BOOL isMoving;
@property (nonatomic) BOOL isIncreasingAccuracy;

@end

@implementation MMLocationTracker

- (MMLocationTracker *)init
{
    if (self = [super init]) {
        self.distanceFilterStillSVale = DEFAULT_DISTANCE_FILTER_STILL_S_VALUE;
        self.distanceFilterStill = DEFAULT_DISTANCE_FILTER_STILL;
        self.distanceFilterMoving = DEFAULT_DISTANCE_FILTER_MOVING;
        self.intervalStillLocationUpdate = DEFAULT_INTERVAL_STILL_LOCATION_UPDATE;
        self.intervalAccuracyIncrease = DEFAULT_INTERVAL_ACCURACY_INCREASE;
        self.locationUpdateDesiredAccuracy = DEFAULT_LOCATION_UPDATE_DESIRED_ACCURACY;
        self.debug = NO;
        
        
        self.isMoving = NO;
        self.isIncreasingAccuracy = NO;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.locationManager.desiredAccuracy = [self locationAccuracyFromKey:ACCURACY_LOW_KEY];
        self.locationManager.distanceFilter = self.distanceFilterStill;
        [self.locationManager startUpdatingLocation];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    // If no location has been sent, and locationManager is not increasing accuracy...
    if (!self.lastUpdatedLocation && !self.isIncreasingAccuracy) {
        // Should increase accuracy to send first location.
        [self startAccuracyIncrease];
    }
    
    // Should only continue if new location is not too close to lastUpdatedLocation, or if locationManager is increasing accuracy...
    if (self.isIncreasingAccuracy || [location distanceFromLocation:self.lastUpdatedLocation] > self.isMoving ? self.distanceFilterMoving : self.distanceFilterStill) {
        
        // Determine if it has started moving...
        float locationStdDev = location.horizontalAccuracy / 3.00f;
        float locationSValue = ([location distanceFromLocation:self.lastUpdatedLocation] - self.distanceFilterStill) / locationStdDev;
        if (!self.isMoving && locationSValue > self.distanceFilterStillSVale) {
            // Started moving...
            self.isMoving = YES;
            self.startMovingDate = [NSDate date];
            self.locationManager.distanceFilter = self.distanceFilterMoving;
            self.locationStillTimer = [NSTimer scheduledTimerWithTimeInterval:self.intervalStillLocationUpdate target:self selector:@selector(stillIntervalTimeout) userInfo:nil repeats:NO];
            
            // Delegate method.
            if ([self.delegate respondsToSelector:@selector(locationTrackerDidStartMoving:)]) {
                [self.delegate locationTrackerDidStartMoving:self];
            }
        }
        
        // If it is already moving, and received another location update...
        if (self.isMoving) {
            // Restart locationStillTimer
            [self.locationStillTimer invalidate];
            self.locationStillTimer = [NSTimer scheduledTimerWithTimeInterval:self.intervalStillLocationUpdate target:self selector:@selector(stillIntervalTimeout) userInfo:nil repeats:NO];
        }
        
        // If it is increasing accuracy, and the accuracy reached the desired value...
        if (self.isIncreasingAccuracy && location.horizontalAccuracy <= self.locationUpdateDesiredAccuracy) {
            // Should send location update
            [self locationUpdate:location];
        }
        
    }
    
    self.lastLocation = location;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // Handle Error
    if ([self.delegate respondsToSelector:@selector(locationTracker:didFailWithError:)]) {
        [self.delegate locationTracker:self didFailWithError:error];
    }
}

- (void)stillIntervalTimeout
{
    // It was still for long enough... Increase accuracy to update location!
    [self startAccuracyIncrease];
}

- (void)startAccuracyIncrease
{
    self.isIncreasingAccuracy = YES;
    self.startAccuracyIncreaseDate = [NSDate date];
    self.locationManager.desiredAccuracy = [self locationAccuracyFromKey:ACCURACY_HIGH_KEY];
    self.accuracyIncreaseTimer = [NSTimer scheduledTimerWithTimeInterval:self.intervalAccuracyIncrease target:self selector:@selector(accuracyIncreaseTimeout) userInfo:nil repeats:NO];
}

- (void)accuracyIncreaseTimeout
{
    // Accuracy didn't increase to desired value in time. Update to lastLocation.
    [self locationUpdate:self.lastLocation];
}

- (void)locationUpdate:(CLLocation *)location
{
    self.isMoving = NO;
    self.isIncreasingAccuracy = NO;
    self.startMovingDate = nil;
    self.startAccuracyIncreaseDate = nil;
    self.locationManager.desiredAccuracy = [self locationAccuracyFromKey:ACCURACY_LOW_KEY];
    self.locationManager.distanceFilter = self.distanceFilterStill;
    [self.accuracyIncreaseTimer invalidate];
    
    // Only update if far enough away from lastUpdatedLocation.
    if ([location distanceFromLocation:self.lastUpdatedLocation] > self.distanceFilterStill) {
        // Location was updated.
        if ([self.delegate respondsToSelector:@selector(locationTracker:didStopMovingWithLocationUpdate:)]) {
            [self.delegate locationTracker:self didStopMovingWithLocationUpdate:location];
        }
        self.lastUpdatedLocation = location;
    } else {
        // Location was not updated.
        if ([self.delegate respondsToSelector:@selector(locationTracker:didStopMovingWithLocationUpdate:)]) {
            [self.delegate locationTracker:self didStopMovingWithLocationUpdate:nil];
        }
    }
}

- (void)setDistanceFilterStill:(CGFloat)distanceFilterStill
{
    _distanceFilterStill = distanceFilterStill;
    if (!self.isMoving) self.locationManager.distanceFilter = distanceFilterStill;
}

- (void)setDistanceFilterMoving:(CGFloat)distanceFilterMoving
{
    _distanceFilterMoving = distanceFilterMoving;
    if (self.isMoving) self.locationManager.distanceFilter = distanceFilterMoving;
}

- (CLLocationAccuracy)locationAccuracyFromKey:(NSInteger)key
{
    CLLocationAccuracy accuracy = 0.0;
    switch (key) {
        case 0:  accuracy = kCLLocationAccuracyBestForNavigation; break;
        case 1:  accuracy = kCLLocationAccuracyBest;              break;
        case 2:  accuracy = kCLLocationAccuracyNearestTenMeters;  break;
        case 3:  accuracy = kCLLocationAccuracyHundredMeters;     break;
        case 4:  accuracy = kCLLocationAccuracyKilometer;         break;
        case 5:  accuracy = kCLLocationAccuracyThreeKilometers;   break;
        default: accuracy = kCLLocationAccuracyThreeKilometers;   break;
    }
    return accuracy;
}

@end
