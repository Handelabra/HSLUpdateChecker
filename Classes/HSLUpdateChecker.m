//
//  HSLUpdateChecker.m
//  HSL Common Library
//
//  Created by John Arnold on 2012-08-14.
//  Copyright (c) 2012 Handelabra Studio LLC. All rights reserved.
//

#import "HSLUpdateChecker.h"

@interface HSLUpdateChecker ()

@property (nonatomic, copy) NSString *updateUrl; // We need to remember the URL for the default alert handler

@end

@implementation HSLUpdateChecker

+ (HSLUpdateChecker *) sharedUpdateChecker
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

+ (void)checkForUpdate
{
    [self checkForUpdateWithHandler:^(NSString *appStoreVersion, NSString *localVersion, NSString *releaseNotes, NSString *updateURL) {

        // Remember the URL for the alert delegate
        [HSLUpdateChecker sharedUpdateChecker].updateUrl = updateURL;

        NSString *titleFormat = NSLocalizedString(@"Version %@ Now Available", @"HSLUpdateChecker upgrade alert message title. The argument is the version number of the update.");
        NSString *messageFormat = NSLocalizedString(@"New in this version:\n%@", @"HSLUpdateChecker upgrade alert message text. The argument is the release notes for the update.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, appStoreVersion]
                                                        message:[NSString stringWithFormat:messageFormat, releaseNotes]
                                                       delegate:[HSLUpdateChecker sharedUpdateChecker]
                                              cancelButtonTitle:NSLocalizedString(@"Not Now", @"HSLUpdateChecker upgrade alert 'Not Now' button.")
                                              otherButtonTitles:NSLocalizedString(@"Update", @"HSLUpdateChecker upgrade alert 'Update' button."), nil];
        [alert show];
    }];
}

+ (void) checkForUpdateWithHandler:(void (^)(NSString *appStoreVersion, NSString *localVersion, NSString *releaseNotes, NSString *updateURL))handler
{
    // Go to a background thread for the update check.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSLocale *locale = [NSLocale currentLocale];
        NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
        NSString *languageCode = [locale objectForKey:NSLocaleLanguageCode];
        NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@&country=%@&lang=%@", bundleId, countryCode, languageCode];
        NSURL *url = [NSURL URLWithString:urlString];

        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfURL:url];
        
        if (jsonData)
        {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            
            if (error)
            {
                NSLog(@"HSLUpdateChecker: Error parsing JSON from iTunes API: %@", error);
            }
            else
            {
                NSArray *results = dict[@"results"];
                if (results.count > 0)
                {
                    NSDictionary *result = results[0];
                    NSString *appStoreVersion = result[@"version"];
                    
                    // We first try for CFBundleShortVersionString which is normally the user-visible version string
                    NSString *localVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                    if (!localVersion)
                    {
                        // Try using CFBundleVersion instead
                        localVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
                    }
                    
                    if (localVersion && ![localVersion isEqualToString:appStoreVersion])
                    {
                        // Different! Tell our handler about it if we haven't already for this appStoreVersion.
                        NSString *checkedAppStoreVersionKey = [NSString stringWithFormat:@"HSL_UPDATE_CHECKER_CHECKED_%@", appStoreVersion];
                        if (![[NSUserDefaults standardUserDefaults] boolForKey:checkedAppStoreVersionKey])
                        {
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:checkedAppStoreVersionKey];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSString *updateUrl = result[@"trackViewUrl"];
                            NSString *releaseNotes = result[@"releaseNotes"];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (handler)
                                {
                                    handler(appStoreVersion, localVersion, releaseNotes, updateUrl);
                                }
                            });
                        }
                    }
                }
            }
        }
        else
        {
            // Handle Error
            NSLog(@"HSLUpdateChecker: Received no data from iTunes API");
        }
    });
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        // Go to the app store
        NSURL *url = [NSURL URLWithString:self.updateUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
