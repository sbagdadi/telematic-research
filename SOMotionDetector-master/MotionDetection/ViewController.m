//
//  ViewController.m
//  MotionDetection
//
// The MIT License (MIT)
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "ViewController.h"
#import "SOMotionDetector.h"
#import "SOStepDetector.h"

@interface ViewController ()
{
    int stepCount;
}
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *motionTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *isShakingLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        if (orientation == UIDeviceOrientationFaceDown) {
            // device facing down
            NSLog(@"Device facing Down");
            _stepCountLabel.text = @"Device Facing Down";
        }else if (orientation == UIDeviceOrientationFaceUp) {
            // device facing up
            NSLog(@"Device facing Up");
            _stepCountLabel .text = @"Device Facing Up";
        }else{
            // facing some other direction
        }
        
//        if (orientation == UIDeviceOrientationPortrait) {
//            NSLog(@"Device in Portrait Mode");
//        }else if (orientation == UIDeviceOrientationLandscapeLeft){
//            NSLog(@"Device in LandScapeLeft");
//        }else if (orientation == UIDeviceOrientationLandscapeRight){
//            NSLog(@"Device in LandScapeRight");
//        }
        
    }];
    

    [self.locationManager startUpdatingLocation];
    __weak ViewController *weakSelf = self;
    [SOMotionDetector sharedInstance].motionTypeChangedBlock = ^(SOMotionType motionType) {
        NSString *type = @"";
        switch (motionType) {
            case MotionTypeNotMoving:
                type = @"Not moving";
                break;
            case MotionTypeWalking:
                type = @"Walking";
                break;
            case MotionTypeRunning:
                type = @"Running";
                break;
            case MotionTypeAutomotive:
                type = @"Automotive";
                break;
        }
        
        weakSelf.motionTypeLabel.text = type;
    };
    
    [SOMotionDetector sharedInstance].locationChangedBlock = ^(CLLocation *location) {
        weakSelf.speedLabel.text = [NSString stringWithFormat:@"%.2f km/h",[SOMotionDetector sharedInstance].currentSpeed * 3.6f];
        NSLog(@"speed %f",[SOMotionDetector sharedInstance].currentSpeed);
    };
    
    //[SOMotionDetector sharedInstance].currentSpeed * 3.6f]
    [SOMotionDetector sharedInstance].accelerationChangedBlock = ^(CMAcceleration acceleration) {
        BOOL isShaking = [SOMotionDetector sharedInstance].isShaking;
        weakSelf.isShakingLabel.text = isShaking ? @"shaking":@"not shaking";
    };
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [SOMotionDetector sharedInstance].useM7IfAvailable = YES; //Use M7 chip if available, otherwise use lib's algorithm
    }
    
    //This is required for iOS > 9.0 if you want to receive location updates in the background
    [SOLocationManager sharedInstance].allowsBackgroundLocationUpdates = YES;
    
    //Starting motion detector
    [[SOMotionDetector sharedInstance] startDetection];
    
    //Starting pedometer
    [[SOStepDetector sharedInstance] startDetectionWithUpdateBlock:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        stepCount++;
        //self.stepCountLabel.text = [NSString stringWithFormat:@"Step count: %d", stepCount];
    }];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
//    double lati = newLocation.coordinate.latitude;
//    NSString * geocoder_latitude_str= [NSString stringWithFormat:@"%.4f",lati];
//    [curent_lat_ary addObject:_geocoder_latitude_str];
//    double longi = newLocation.coordinate.longitude;
//    NSString * geocoder_longitude_str=[NSString stringWithFormat:@"%.4f",longi];
//    [cureent_log_ary addObject:_geocoder_longitude_str];
//    NSUserDefaults *current_lat=[NSUserDefaults standardUserDefaults];
//    [current_lat setObject:_geocoder_latitude_str forKey:@"current_lat"];
//    [current_lat setObject:_geocoder_longitude_str forKey:@"current_long"];
    //[locationManager stopUpdatingLocation];
    
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
    
    [reverseGeocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        // NSLog(@"Received placemarks: %@", placemarks);
        
        CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
        NSString *countryCode = myPlacemark.ISOcountryCode;
        NSString *countryName = myPlacemark.country;
        NSString *cityName= myPlacemark.subAdministrativeArea;
        NSArray *lines = myPlacemark.addressDictionary[ @"FormattedAddressLines"];
        NSString *addressString = [lines componentsJoinedByString:@"\n"];
        NSLog(@"My country code: %@ and countryName: %@ MyCity: %@", countryCode, countryName, cityName);
        self.lbAddress.text = addressString;
        NSString *currentspeed = [NSString stringWithFormat:@"SPEED: %f", [newLocation speed]];
        self.stepCountLabel.text = currentspeed;
        
        
    }];
}



@end
