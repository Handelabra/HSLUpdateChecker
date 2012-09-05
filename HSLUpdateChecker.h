//
//  HSLUpdateChecker.h
//  HSL Common Library
//
//  Created by John Arnold on 2012-08-14.
//  Copyright (c) 2012 Handelabra Studio LLC. All rights reserved.
//

// Simple update checker, requires iOS 5+ and ARC.

// It uses your app's bundle identifier to ask the app store about the app,
// and if the version on the app store is different, it presents an alert with
// the "What's New" text and a button to go directly to the app store.

// The check and alert will only be performed once per version (so that if a
// user declines, they do not continue to get bothered).

@interface HSLUpdateChecker : NSObject <UIAlertViewDelegate>

+ (void) checkForUpdate;

@end
