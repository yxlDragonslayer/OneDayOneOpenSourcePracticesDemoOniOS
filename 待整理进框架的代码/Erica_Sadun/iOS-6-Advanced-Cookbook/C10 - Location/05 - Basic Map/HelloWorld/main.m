/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>

#import "Utility.h"

#define MAX_TIME	10

@interface TestBedViewController : UIViewController <CLLocationManagerDelegate>
@end

@implementation TestBedViewController
{
    MKMapView *mapView;

    CLLocationManager *manager;
    CLLocation *bestLocation;
	int timespent;
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([CLLocationManager authorizationStatus] ==
        kCLAuthorizationStatusDenied)
    {
        NSLog(@"User has denied location services");
        return;
    }
    
    NSLog(@"Location manager error: %@", error.localizedDescription);
    return;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    
	// Keep track of the best location found
	if (!bestLocation)
        bestLocation = newLocation;
	else if (newLocation.horizontalAccuracy <  bestLocation.horizontalAccuracy)
        bestLocation = newLocation;
	
	mapView.region = MKCoordinateRegionMake(bestLocation.coordinate, MKCoordinateSpanMake(0.1f, 0.1f));
	mapView.showsUserLocation = YES;
	mapView.zoomEnabled = NO;
}

// Search for n seconds to get the best location during that time
- (void) tick: (NSTimer *) timer
{
	if (++timespent == MAX_TIME)
	{
		// Invalidate the timer
		[timer invalidate];
		
		// Stop the location task
		[manager stopUpdatingLocation];
		manager.delegate = nil;
		
		// Restore the find me button
		self.navigationItem.rightBarButtonItem = BARBUTTON(@"Find Me", @selector(findme));
		
		if (!bestLocation)
		{
			// no location found
			self.title = @"";
			return;
		}
        
		// Note the accuracy in the title bar
		self.title = [NSString stringWithFormat:@"%0.1f meters", bestLocation.horizontalAccuracy];
		
		// Update the map and allow user interaction
		// [mapView setRegion:MKCoordinateRegionMake(self.bestLocation.coordinate, MKCoordinateSpanMake(0.005f, 0.005f)) animated:YES];
		[mapView setRegion:MKCoordinateRegionMakeWithDistance(bestLocation.coordinate, 500.0f, 500.0f) animated:YES];
        
		mapView.showsUserLocation = YES;
		mapView.zoomEnabled = YES;
	}
	else
		self.title = [NSString stringWithFormat:@"%d secs remaining", MAX_TIME - timespent];
}

- (void) findme
{
	// disable right button
	self.navigationItem.rightBarButtonItem = nil;
	
	// Search for the best location
	timespent = 0;
	bestLocation = nil;
	manager.delegate = self;
	[manager startUpdatingLocation];
	[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}

- (void) loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 320.0f)];
    [self.view addSubview:mapView];
    PREPCONSTRAINTS(mapView);
    STRETCH_VIEW(self.view, mapView);
    
	if (!CLLocationManager.locationServicesEnabled)
	{
		NSLog(@"User has opted out of location services");
		return;
	}
	else
	{
		// User generally allows location calls
        manager = [[CLLocationManager alloc] init];
		manager.desiredAccuracy = kCLLocationAccuracyBest;
		self.navigationItem.rightBarButtonItem = BARBUTTON(@"Find Me", @selector(findme));
	}
    
     // Infinite Loop -- for chapter screen shots
//    CLLocation *location = [[CLLocation alloc] initWithLatitude:37.33168400 longitude:-122.03075800];
//    mapView.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.005f, 0.005f));
//    mapView.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.1f, 0.1f));
}
@end

#pragma mark -

#pragma mark Application Setup
@interface TestBedAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
}
@end
@implementation TestBedAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{	
    // [application setStatusBarHidden:YES];
    [[UINavigationBar appearance] setTintColor:COOKBOOK_PURPLE_COLOR];
    
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	TestBedViewController *tbvc = [[TestBedViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tbvc];
    window.rootViewController = nav;
	[window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool {
        int retVal = UIApplicationMain(argc, argv, nil, @"TestBedAppDelegate");
        return retVal;
    }
}