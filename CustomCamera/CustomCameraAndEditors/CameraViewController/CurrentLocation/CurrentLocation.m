//
//  CurrentLocation.m
//  Skoop
//
//  Created by Pargat  Dhillon on 09/09/15.
//  Copyright (c) 2015 Pargat Dhillon. All rights reserved.
//

#import "CurrentLocation.h"
#import <UIKit/UIKit.h>
//#import "User.h"
//#import "Utilities.h"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

@interface CurrentLocation(){
    BOOL updateCalled;
    UIBackgroundTaskIdentifier bgTaskId;
}
@end

@implementation CurrentLocation

+ (CurrentLocation *)sharedInstance
{
    static CurrentLocation *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[CurrentLocation alloc] init];
    });
    return singleton;
}

- (id)init {
    if (self == [super init]) {
        self.myLocationArray = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)updateCurrentLocation{
    if (self.locationManager == nil) {
        [self locationInitialiser];
    }
    else if(!_currentLocation || [[NSDate date]timeIntervalSinceDate:self.updatedAt] > 30)
        [self.locationManager startUpdatingLocation];
    else{
        if(_success)
            _success(_currentLocation);
    }
}

-(void)getCurrentLocation:(BOOL)update success:(SuccessLocation)success failure:(FailureLocation)failure{
    _success = success;
    _failure = failure;
    if (self.locationManager.location.coordinate.latitude==0 && self.locationManager.location.coordinate.longitude == 0) {
        [self locationInitialiser];
    }
    else if (update){
        [self updateCurrentLocation];
    }
    else{
        if(_success)
            _success(_currentLocation);
    }
}

#pragma mark -
#pragma mark - Location manager handling
-(void)locationInitialiser
{
    if ([CLLocationManager locationServicesEnabled] == NO) {
        if(_failure){
            _failure(nil);
            _failure = nil;
        }
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        return;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [self.locationManager requestWhenInUseAuthorization];
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    switch (status) {
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLocationTracking];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:{
            UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Permission Denied" message:@"Re-launch the application again, after turning on Location Service for this app to update your current location." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [servicesDisabledAlert show];
        }
            break;

        default:
            break;
    }
}

- (void)startLocationTracking {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (!_locationManager || status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self locationInitialiser];
    }
    
    CLLocationManager *locationManager = self.locationManager;
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = 500;
    
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self updateCurrentLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        //        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        //        if (locationAge > 30.0)
        //        {
        //            continue;
        //        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.myLocationArray addObject:dict];
            
            if (self.currentLocation == nil) {
                self.currentLocation = newLocation;
                self.myLocationAccuracy = theAccuracy;
            }
        }
    }
    
    if(updateCalled)
        return;
    
    [self performSelector:@selector(stopLocationUpdation) withObject:nil afterDelay:5];

    updateCalled = YES;
}

-(void)stopLocationUpdation{
    [self.locationManager stopUpdatingLocation];
    if(_success){
        _success(_currentLocation);
        _success = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if(_failure){
        _failure(error);
        _failure = nil;
    }
    [self.locationManager stopUpdatingLocation];
}

+(void)getAddressAtLocation:(CLLocation *)currentLocation success:(void (^) (NSString *address))success{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         CLPlacemark *placemark;
         
         if (error == nil && [placemarks count] > 0)
         {
             placemark = [placemarks lastObject];
             
             // strAdd -> take bydefault value nil
             NSString *strAdd = nil;
             
             if ([placemark.subThoroughfare length] != 0)
                 strAdd = placemark.subThoroughfare;
             
             if ([placemark.thoroughfare length] != 0)
             {
                 // strAdd -> store value of current location
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark thoroughfare]];
                 else
                 {
                     // strAdd -> store only this value,which is not null
                     strAdd = placemark.thoroughfare;
                 }
             }
             
             if ([placemark.postalCode length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
                 else
                     strAdd = placemark.postalCode;
             }
             
             if ([placemark.locality length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark locality]];
                 else
                     strAdd = placemark.locality;
             }
             
             if ([placemark.administrativeArea length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark administrativeArea]];
                 else
                     strAdd = placemark.administrativeArea;
             }
             
             if ([placemark.country length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark country]];
                 else
                     strAdd = placemark.country;
             }
             
             success(strAdd);
         }
         else{
             success(@"");
         }
     }];
}


@end
