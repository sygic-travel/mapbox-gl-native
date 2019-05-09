#import "MBXAppDelegate.h"
#import "MBXViewController.h"
#import <Mapbox/Mapbox.h>

@interface MBXAppDelegate() <MGLMetricsManagerDelegate>

@end

@implementation MBXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self performDataReset];

    // Set access token, unless MGLAccountManager already read it in from Info.plist.
    if ( ! [MGLAccountManager accessToken]) {
		NSString *accessToken = @"pk.eyJ1IjoibWlzYWNlayIsImEiOiJjanJ0cWRncWUyZnowNDRudGM5d3FuY3VmIn0.FtuzbY1Qq21j4F_sIk3F4g";
        if (accessToken) {
            // Store to preferences so that we can launch the app later on without having to specify
            // token.
            [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"MBXMapboxAccessTokenDefaultsKey"];
        } else {
            // Try to retrieve from preferences, maybe we've stored them there previously and can reuse
            // the token.
            accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"MBXMapboxAccessTokenDefaultsKey"];
        }
//        [MGLAccountManager setAccessToken:accessToken];
	}

#ifndef MGL_DISABLE_LOGGING
    [MGLLoggingConfiguration sharedConfiguration].loggingLevel = MGLLoggingLevelFault;
#endif

    [MGLMetricsManager sharedManager].delegate = self;
    return YES;
}

#pragma mark - Quick actions

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    completionHandler([self handleShortcut:shortcutItem]);
}

- (BOOL)handleShortcut:(UIApplicationShortcutItem *)shortcut {
    if ([[shortcut.type componentsSeparatedByString:@"."].lastObject isEqual:@"settings"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        });

        return YES;
    }

    return NO;
}

- (BOOL)metricsManager:(MGLMetricsManager *)metricsManager shouldHandleMetric:(MGLMetricType)metricType {
    return YES;
}

- (void)metricsManager:(MGLMetricsManager *)metricsManager didCollectMetric:(MGLMetricType)metricType withAttributes:(NSDictionary *)attributes {
    [[MGLMetricsManager sharedManager] pushMetric:metricType withAttributes:attributes];
}

#define NSDocumentsDirectory()   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define NSLibraryDirectory()     [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,  NSUserDomainMask, YES) firstObject]
#define NSCachesDirectory()      [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,   NSUserDomainMask, YES) firstObject]
#define BUNDLE_IDENTIFIER  [[NSBundle mainBundle] bundleIdentifier]

- (void)performDataReset
{
	// Clean-up all data folders
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *folders = @[ NSCachesDirectory(), NSDocumentsDirectory(), NSTemporaryDirectory(), NSLibraryDirectory() ];

	// Clear all files in 'folders' except for skipped ones
	for (NSString *folder in folders)
		for (NSString *file in [fm contentsOfDirectoryAtPath:folder error:NULL])
			[fm removeItemAtPath:[folder stringByAppendingPathComponent:file] error:NULL];

	// Remove all plists from Preferences except for Sygic Maps SDK
	NSString *folder = [NSLibraryDirectory() stringByAppendingPathComponent:@"Preferences"];
	for (NSString *file in [fm contentsOfDirectoryAtPath:folder error:NULL])
		[fm removeItemAtPath:[folder stringByAppendingPathComponent:file] error:NULL];

	// Clear cached standard user defaults
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:BUNDLE_IDENTIFIER];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
