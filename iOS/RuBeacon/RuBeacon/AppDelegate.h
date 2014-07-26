//
//  AppDelegate.h
//  RuBeacon
//
//  Created by Denis on 27.07.14.
//  Copyright (c) 2014 RuBeacon. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreLocation;
@import CoreBluetooth;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, unsafe_unretained) void *operationContext;
@property (weak, nonatomic) IBOutlet UILabel *numberOfBeacons;
@property (weak, nonatomic) IBOutlet UILabel *majorsList;
@property (weak, nonatomic) IBOutlet UILabel *nearBeacons;
@property (weak, nonatomic) IBOutlet UILabel *farBeacons;
@property (weak, nonatomic) IBOutlet UILabel *immediateBeacons;

@end
