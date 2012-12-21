HSLUpdateChecker
================

Simple update checker for iOS apps that displays an alert view with update release notes and the option to go to the App Store when an update for your app is available on the App Store. 

Simply drop it into your app project and call the class method checkForUpdate at an appropriate time after app launch completes. It stores its data in user defaults and only prompts users to update once per version.

It uses the iTunes search API to lookup your app info by its bundle identifier. 
http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html

Requires iOS 5+, ARC, and Apple Generic Versioning (see below).
http://useyourloaf.com/blog/2010/08/18/setting-iphone-application-build-versions.html
