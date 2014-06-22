//
//  MMLocationTracker.h
//  Location2
//
//  Created by Manuel Menzella on 1/6/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>\

@protocol MMLocationTrackerDelegate;

@interface MMLocationTracker : NSObject

// ADD DEBUG NSLogs (!)

@property (nonatomic) CGFloat distanceFilterStillSVale;
@property (nonatomic) CGFloat distanceFilterStill;
@property (nonatomic) CGFloat distanceFilterMoving;
@property (nonatomic) CGFloat intervalStillLocationUpdate;
@property (nonatomic) CGFloat intervalAccuracyIncrease;
@property (nonatomic) CGFloat locationUpdateDesiredAccuracy;

@property (nonatomic, assign) NSObject <MMLocationTrackerDelegate> *delegate;

@property (nonatomic) BOOL debug;

@end


@protocol MMLocationTrackerDelegate
@optional

// Optional Delegate Methods
- (void)locationTrackerDidStartMoving:(MMLocationTracker *)locationTracker;
- (void)locationTracker:(MMLocationTracker *)locationTracker didStopMovingWithLocationUpdate:(CLLocation *)location; // location may be nil if very close to last location update
- (void)locationTracker:(MMLocationTracker *)locationTracker didFailWithError:(NSError *)error;

@end