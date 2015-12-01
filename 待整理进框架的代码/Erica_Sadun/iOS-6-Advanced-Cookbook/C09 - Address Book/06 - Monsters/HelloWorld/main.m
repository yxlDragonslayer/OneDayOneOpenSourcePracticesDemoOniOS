/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import "FakePerson.h"
#import "Utility.h"
#import "ABWrappers.h"

#define IMAGEFILE(BASEFILE, MAXNUM) [NSString stringWithFormat:BASEFILE, (rand() % MAXNUM) + 1]

@interface TestBedViewController : UIViewController  <ABUnknownPersonViewControllerDelegate, ABPersonViewControllerDelegate>
@end

@implementation TestBedViewController
{
     UIImageView *imageView;
}

// Graphics adapted from: http://www.splitbrain.org/go/monsterid
- (UIImage *) randomImage
{
    // Build a random image based on the monster id art
    
    CGSize size = CGSizeMake(120.0f, 120.0f);
    CGRect rect = (CGRect){.size = size};
    UIGraphicsBeginImageContext(size);    
    UIImage *part;
    part = [UIImage imageNamed:IMAGEFILE(@"oldarms_%d.png", 5)];
    [part drawInRect:rect];
    part = [UIImage imageNamed:IMAGEFILE(@"oldlegs_%d.png", 5)];
    [part drawInRect:rect];
    part = [UIImage imageNamed:IMAGEFILE(@"oldhair_%d.png", 5)];
    [part drawInRect:rect];
    part = [UIImage imageNamed:IMAGEFILE(@"oldbody_%d.png", 15)];
    [part drawInRect:rect];
    part = [UIImage imageNamed:IMAGEFILE(@"oldmouth_%d.png", 10)];
    [part drawInRect:rect];
    part = [UIImage imageNamed:IMAGEFILE(@"oldeyes_%d.png", 15)];
    [part drawInRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark Unknown Person Delegate Methods
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
    // Handle cancel events
    if (!person) return;
    
    ABPersonViewController *abpvc = [[ABPersonViewController alloc] init];
    abpvc.displayedPerson = person;
    abpvc.allowsEditing = YES;
    abpvc.personViewDelegate = self;
    
    [self.navigationController pushViewController:abpvc animated:YES];
}

- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}

#pragma mark PERSON DELEGATE
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    return NO;
}

#pragma mark Action

- (void) assignAvatar
{
    ABUnknownPersonViewController *upvc = [[ABUnknownPersonViewController alloc] init];
    upvc.unknownPersonViewDelegate = self;
    
    ABContact *contact = [ABContact contact];
    contact.image = imageView.image;
    
    upvc.allowsActions = NO;
    upvc.allowsAddingToAddressBook = YES;
    upvc.message = @"Who looks like this?";
    upvc.displayedPerson = contact.record;
    
    [self.navigationController pushViewController:upvc animated:YES];
}

- (void) changeAvatar
{
    imageView.image = [self randomImage];
}

- (void) loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    srand(time(0));
    self.navigationItem.leftBarButtonItem = BARBUTTON(@"Change", @selector(changeAvatar));
    self.navigationItem.rightBarButtonItem = BARBUTTON(@"Assign", @selector(assignAvatar));
    
    imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.image = [self randomImage];
    [self.view addSubview:imageView];
    PREPCONSTRAINTS(imageView);
    STRETCH_VIEW(self.view, imageView);
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
    srandom(time(0));
    
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