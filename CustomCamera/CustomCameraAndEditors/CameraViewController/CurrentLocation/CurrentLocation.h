//
//  CurrentLocation.h
//  Skoop
//
//  Created by Pargat  Dhillon on 09/09/15.
//  Copyright (c) 2015 Pargat Dhillon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^SuccessLocation)(CLLocation *location);
typedef void (^FailureLocation)(NSError *error);

@interface CurrentLocation : NSObject<CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;
@property (strong, nonatomic) NSDate *updatedAt;
@property(strong, nonatomic) SuccessLocation success;
@property(strong, nonatomic) FailureLocation failure;
@property (nonatomic) NSMutableArray *myLocationArray;
@property (strong, nonatomic) NSTimer *timer;

-(void)getCurrentLocation:(BOOL)update success:(SuccessLocation)success failure:(FailureLocation)failure;
+(void)getAddressAtLocation:(CLLocation *)currentLocation success:(void (^) (NSString *address))success;
+(CurrentLocation *)sharedInstance;

@end
