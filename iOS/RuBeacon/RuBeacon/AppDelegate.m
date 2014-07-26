//
//  AppDelegate.m
//  RuBeacon
//
//  Created by Denis on 27.07.14.
//  Copyright (c) 2014 RuBeacon. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

static NSString * const kUUID = @"9F4916B1-0864-49BC-8F09-1445F9FABDEF";

static NSString * const kIdentifier = @"SomeIdentifier";

static NSString * const kOperationCellIdentifier = @"OperationCell";
static NSString * const kBeaconsHeaderViewIdentifier = @"BeaconsHeader";

static void * const kMonitoringOperationContext = (void *)&kMonitoringOperationContext;
static void * const kRangingOperationContext = (void *)&kRangingOperationContext;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MainViewController* mainViewController = [MainViewController new];
    [self.window setRootViewController:mainViewController];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - From Index Path commented

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

#pragma mark - Common

- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

#pragma mark - Beacon ranging

- (void)changeRangingState:sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startRangingForBeacons];
    } else {
        [self stopRangingForBeacons];
    }
}

- (void)startRangingForBeacons
{
    self.operationContext = kRangingOperationContext;
    
    [self createLocationManager];
    
    self.detectedBeacons = [NSArray array];
    [self turnOnRanging];
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        //self.rangingSwitch.on = NO;
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    /*    NSIndexSet *deletedSections = [self deletedSections];
     self.detectedBeacons = [NSArray array];
     
     [self.beaconTableView beginUpdates];
     if (deletedSections)
     [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
     [self.beaconTableView endUpdates];
     */
    NSLog(@"Turned off ranging.");
}

#pragma mark - Beacon region monitoring

- (void)changeMonitoringState:sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startMonitoringForBeacons];
    } else {
        [self stopMonitoringForBeacons];
    }
}

- (void)startMonitoringForBeacons
{
    self.operationContext = kMonitoringOperationContext;
    
    [self createLocationManager];
    
    [self turnOnMonitoring];
}

- (void)turnOnMonitoring
{
    NSLog(@"Turning on monitoring...");
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
        //self.monitoringSwitch.on = NO;
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"Monitoring turned on for region: %@.", self.beaconRegion);
}

- (void)stopMonitoringForBeacons
{
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"Turned off monitoring");
}

#pragma mark - Location manager delegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (![CLLocationManager locationServicesEnabled]) {
        if (self.operationContext == kMonitoringOperationContext) {
            NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
            //self.monitoringSwitch.on = NO;
            return;
        } else {
            NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
            //self.rangingSwitch.on = NO;
            return;
        }
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        if (self.operationContext == kMonitoringOperationContext) {
            NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
            //self.monitoringSwitch.on = NO;
            return;
        } else {
            NSLog(@"Couldn't turn on ranging: Location services not authorised.");
            //self.rangingSwitch.on = NO;
            return;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
        self.numberOfBeacons.text = @"No";
    } else {
        NSLog(@"Found %lu %@.", (unsigned long)[filteredBeacons count],
              [filteredBeacons count] > 1 ? @"beacons" : @"beacon");
    }
    
    /*
     NSIndexSet *insertedSections = [self insertedSections];
     NSIndexSet *deletedSections = [self deletedSections];
     NSArray *deletedRows = [self indexPathsOfRemovedBeacons:filteredBeacons];
     NSArray *insertedRows = [self indexPathsOfInsertedBeacons:filteredBeacons];
     NSArray *reloadedRows = nil;
     if (!deletedRows && !insertedRows)
     reloadedRows = [self indexPathsForBeacons:filteredBeacons];
     */
    self.detectedBeacons = filteredBeacons;
    /*
     [self.beaconTableView beginUpdates];
     if (insertedSections)
     [self.beaconTableView insertSections:insertedSections withRowAnimation:UITableViewRowAnimationFade];
     if (deletedSections)
     [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
     if (insertedRows)
     [self.beaconTableView insertRowsAtIndexPaths:insertedRows withRowAnimation:UITableViewRowAnimationFade];
     if (deletedRows)
     [self.beaconTableView deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationFade];
     if (reloadedRows)
     [self.beaconTableView reloadRowsAtIndexPaths:reloadedRows withRowAnimation:UITableViewRowAnimationNone];
     [self.beaconTableView endUpdates];
     */
    [self reportMajors:self.detectedBeacons];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered region: %@", region);
    
    [self sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
        case CLRegionStateUnknown:
            stateString = @"unknown";
            break;
    }
    NSLog(@"State changed to %@ for region %@.", stateString, region);
}

#pragma mark - Local notifications
- (void)sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region {
    UILocalNotification *notification = [UILocalNotification new];
    
    // Notification details
    notification.alertBody = [NSString stringWithFormat:@"Entered beacon region for UUID: %@",
                              region.proximityUUID.UUIDString];   // Major and minor are not available at the monitoring stage
    notification.alertAction = NSLocalizedString(@"View Details", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - Beacon advertising
- (void)changeAdvertisingState:sender {
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startAdvertisingBeacon];
    } else {
        [self stopAdvertisingBeacon];
    }
}

- (void)startAdvertisingBeacon {
    NSLog(@"Turning on advertising...");
    
    [self createBeaconRegion];
    
    if (!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self turnOnAdvertising];
}

- (void)turnOnAdvertising {
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        //self.advertisingSwitch.on = NO;
        return;
    }
    
    time_t t;
    srand((unsigned) time(&t));
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:rand()
                                                                     minor:rand()
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"Turning on advertising for region: %@.", region);
}

- (void)stopAdvertisingBeacon {
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Turned off advertising.");
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error {
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
        //self.advertisingSwitch.on = NO;
        return;
    }
    
    if (peripheralManager.isAdvertising) {
        //NSLog(@"Turned on advertising.");
        //self.advertisingSwitch.on = YES;
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager*)peripheralManager {
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        //self.advertisingSwitch.on = NO;
        return;
    }
    
    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}

- (void)reportMajors:(NSArray *)beacons {
    self.numberOfBeacons.text = [NSString stringWithFormat:@"%lu", (unsigned long)[beacons count]];
    self.majorsList.text = @"";
    self.immediateBeacons.text = @"";
    self.nearBeacons.text = @"";
    self.farBeacons.text = @"";
    for (NSUInteger number = 0; number < beacons.count; number++) {
        CLBeacon *currBeacon = [beacons objectAtIndex:number];
        NSString *identifier = [NSString stringWithFormat:@"%@ ", currBeacon.major];
        self.majorsList.text = [self.majorsList.text stringByAppendingString:identifier];
        switch (currBeacon.proximity) {
            case CLProximityNear: {
                //self.nearBeacons.text = [self.nearBeacons.text stringByAppendingString:identifier];
                break;
            }
            case CLProximityImmediate: {
                //self.immediateBeacons.text = [self.immediateBeacons.text stringByAppendingString:identifier];
                break;
            }
            case CLProximityFar: {
                //self.farBeacons.text = [self.farBeacons.text stringByAppendingString:identifier];
                break;
            }
            case CLProximityUnknown:
            default:
                break;
        }
    }
}

@end
