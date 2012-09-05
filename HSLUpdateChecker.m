//
//  HSLUpdateChecker.m
//  HSL Common Library
//
//  Created by John Arnold on 2012-08-14.
//  Copyright (c) 2012 Handelabra Studio LLC. All rights reserved.
//

#import "HSLUpdateChecker.h"

@interface HSLUpdateChecker ()

@property (copy) NSString *updateUrl; // We need to remember the URL for the alert handler

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

+ (void) checkForUpdate
{
    // Go to a background thread for the actual update check.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [[HSLUpdateChecker sharedUpdateChecker] actuallyCheck];
    });
}

- (void) actuallyCheck
{
    // This runs on a background thead
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", bundleId];
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
            NSArray *results = [dict objectForKey:@"results"];
            if (results.count > 0)
            {
                NSDictionary *result = [results objectAtIndex:0];
                NSString *appStoreVersion = [result objectForKey:@"version"];
                
                NSString *localVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                
                if (![localVersion isEqualToString:appStoreVersion])
                {
                    // Different! Present an alert to the user about it if we haven't already for this appStoreVersion.
                    NSString *checkedAppStoreVersionKey = [NSString stringWithFormat:@"HSL_UPDATE_CHECKER_CHECKED_%@", appStoreVersion];
                    if (![[NSUserDefaults standardUserDefaults] boolForKey:checkedAppStoreVersionKey])
                    {
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:checkedAppStoreVersionKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        self.updateUrl = [result objectForKey:@"trackViewUrl"];
                        NSString *releaseNotes = [result objectForKey:@"releaseNotes"];
                        NSString *title = [NSString stringWithFormat:@"Version %@ Now Available", appStoreVersion];
                        NSString *message = [NSString stringWithFormat:@"New in this version:\n%@", releaseNotes];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                           
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                            message:message
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Not Now"
                                                                  otherButtonTitles:@"Update", nil];
                            [alert show];
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
