//
//  AppDelegate.m
//  Tufts
//
//  Created by Amadou Crookes on 4/16/12.
//  Copyright (c) 2012 Amadou Crookes. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize alertedInternetIsNotAvailable = _alertedInternetIsNotAvailable;
@synthesize alertedDate = _alertedDate;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"071ba95265c6dbb6b7377dbaf3bf6f4f_MTE0NDQ1MjAxMi0wNy0yNiAwMDowNzo1MS4xNzczNDY"];
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavBar.png"] forBarMetrics:UIBarMetricsDefault];
    [[UITableView appearance] setSeparatorColor:[UIColor colorWithRed:72.0/255 green:145.0/255 blue:206.0/255 alpha:1]];
    [[UIBarButtonItem appearance] setTintColor:[UIColor darkGrayColor]];
    [[UISegmentedControl appearance] setTintColor:[UIColor darkGrayColor]];
     
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
    self.alertedInternetIsNotAvailable = NO;
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


// Checking if internet is available
// Have it here so any class can check the connection if necessary
// Pass in a view controller that implements didReceiveConnectionResponse to pass back the results
- (void)pingServer
{
    // If they have already been alerted dont bother checking again
    int intervalSinceAlert = [self.alertedDate timeIntervalSinceNow];
    if(self.alertedInternetIsNotAvailable && intervalSinceAlert < 300) {
        return;
    }    
    dispatch_queue_t queue = dispatch_queue_create("Delegate pingServer", nil);
    dispatch_async(queue, ^{
        NSURL *url = [NSURL URLWithString:@"http://www.google.com/"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"HEAD"];
        
        [NSURLConnection sendAsynchronousRequest:request 
                                           queue:[NSOperationQueue mainQueue] 
                               completionHandler:^(NSURLResponse *request, NSData *data, NSError *error) {
                                   if(error && !self.alertedInternetIsNotAvailable) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"Could not access the internet" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                           [alert show];
                                           self.alertedInternetIsNotAvailable = YES;
                                       });
                                   }
                               }];
    });
    dispatch_release(queue);
    self.alertedDate = [NSDate date];
}

- (NSDate*)alertedDate
{
    if(!_alertedDate) {
        _alertedDate = [NSDate distantPast];
    }
    return _alertedDate;
}

@end
