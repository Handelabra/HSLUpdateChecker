HSLUpdateChecker
================

Simple update checker for iOS apps that displays an alert view with update release notes and the option to go to the App Store when an update for your app is available on the App Store. It uses the iTunes search API (http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html) to lookup your app info by its bundle identifier. It is implemented as a singleton with one method called checkForUpdate. Simply drop it into your app project and call the checkForUpdate method at an appropriate time after app launch completes.
