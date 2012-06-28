This is a document that is very much under development. It's a work in progress design for how the architecture for QuickRadar will work.

Process Overview
================

The QBRadarWindowController creates a QBSubmissionManager, which will live for the duration of this submission. The window controller also creates a QBRadar object, which is a model object representing the data the user is trying to submit, and passes it to the QBSubmissionManager. BOOLs generated from the checkboxes used to turn each service on and off are also passed to the QBSubmissionManager (not implemented yet). Then the window controller tells the QBSubmissionManager to start. 

The QBSubmissionManager calls a class method on QRSubmissionService to get a dictionary of all the available submission services. For each service that the user requested, an instance of the appropriate QRSubmissionService subclass is allocated, and populated with the QBRadar object. The QBSubmissionManager has three NSMutableSets to store services: waiting, in progress, and completed. They're all put in the `waiting` set at first.

The QBSubmissionManager goes through all the services in the Waiting set. Any service whose dependencies are satisfied is told to start itself (asynchronously), handed a completion block, and moved into the `inProgress` set. (The point of this dependency system is to get some ordering: we might want a Twitter service to go after the OpenRadar service, so that it could tweet the OpenRadar URL.) Whenever a service finishes, then it is moved into the `completed` set, and the dependency check on all the waiting services is rerun. As soon as all the services are finished, the QBSubmissionManager fires its completed block.

That's the submission and dependency system. As well as that, this new architecture allows for each submission service to provide a view controller (NS or UI as platform appropriate) to configure its settings. These will be displayed in a list in a Preferences window, and would let each service offer its own interface for configuring settings. There will also be one main pane in the Preferences window, for app-wide settings. This bit isn't in place yet.



Classes overview
================

QRRadar:
--------

A model object representing a radar. When created, it's populated with the stuff the user filled in in the app UI. During the submission, services can add their own data to this object. The default Radar service will add the radar number. This is done by `setValue:forKey:` etc. Keys should be defined as constants in the individual service's header file, and should look something like QRRadarNumberKey.

QRSubmissionController
----------------------

Handles the entire submission process. The appropriate UI controller (the window controller on the Mac, the view controller on iOS) will instantiate one of these, and give it two callbacks: one for updating a progress bar, and one for when the submission is finished or fails. QRSubmissionController is capable of returning partial success, where some services succeeded and some failed: it's best to report exactly what happened to the user. If everything (i.e. the initial Radar submission) fails, give the user the option to try again, but if only some later services fail then don't, because we'd spam Apple.

Internally, when told to start, this class enumerates all the submission services in use, and runs any that have satisfied dependencies (i.e. depend on no other service). Whenever a service completes, it does this again. When all services that have been run are complete and there are no more ready to go, it reports back via its completion block.

Whenever a service calls its progress block, the submission controller enumerates the progress values of each active service, and calls its own progress block.

QRSubmissionController is guaranteed to retain each service object while it is active (i.e. until it finishes or fails), unless the submission controller itself is destroyed. Thus, anything that creates a QRSubmissionController must retain it while it is active. Possibly in the future we'll add cancellation methods to the services (to deal with e.g. user quitting app, user closing window, etc).

This is the class that handles sending a Growl notification when the submission is finished. NB make it use the OpenRadar URL as the Growl action if possible.

QRSubmissionService:
--------------------

The superclass of any submission service (eg Radar, OpenRadar, Twitter). Exposes the following APIs:

* identifier: a string to internally identify the service
* name: a human readable name
* hardDependencies: services that must have completed before this service can begin. Return an array of service identifier strings.
* softDependencies: services that should run before this service if they're present, but do not have to be present. Return an array of service identifier strings.
* macSettingsViewControllerClass: return the class of an NSViewController subclass that should display in the Preferences dialog box to allow configuring this service. (Note that the view controller class in question won't have access to an actual instance of the QRSubmissionService --- so it should put all its useful data in NSUserDefaults or the Keychain.)
* iOSSettingsViewControllerClass: like the Mac version above, the class of a UIViewController subclass for configuring service settings on iOS.
* completionStatus: a value from an enum that returns notBegun, inProgress, completed or failed.
* progress: a float (0-1) for the percentage complete.
* isAvailable: a BOOL to specify whether to show the check box in the bug window for enabling/disabling this service, and thus whether the service can be used. Note that this can depend on the stuff in Settings --- if sufficient credentials or whatever are not present, return NO to avoid cluttering the UI with unconfigured services.
* checkBoxString: a string along the lines of "Submit to OpenRadar", describing what will happen when this service is run.
* supportedOnMac: YES if this service runs in the Mac version of QuickRadar.
* supportedOniOS: guess :)

It also has a property for `radar`, and a method `submitAsyncWithProgressBlock:completionBlock:`. The progress block should be run every time the progress for this service changes, so that the QRSubmissionController (which is the thing calling the QRSubmissionService) can request that the GUI be updated.

There's a `validateRadar:error:` method, called on every requested service just before submitting everything. If any of the services return NO, the error is displayed to the user and they are allowed to fix the problems before the submission may be restarted. This is important because if the service failed later on, while it was trying to submit, there may be a partial submission where earlier services succeeded but the operation as a whole did not. This validation is mainly intended to be used by the QRRadarSubmissionService. Note you can't validate the presence of things like a radar number or an OpenRadar URL, since the method is called before any services have been run.

There's a class method called `+submissionServiceClasses` which returns all the service classes the system knows about. Each QRSubmissionService must register itself in `+load`, by calling [self register].

QRRadarSubmissionService
------------------------

The reason we're all here. This class is the one that submits to Radar. Presumably all other submission services will hard depend on this one, since this is the one that adds the Radar number to the model object.

QROpenRadarSubmissionService:
------------------------

Hard depends on QRRadarSubmissionService. Populates QROpenRadarURLKey.

QRSuperURLConnection:
------------------------

This class is designed to wrap NSURLConnection and include helpful methods to create POST requests (with URL encoded or multipart form data). At the moment it has a bit of a thrown together API, but it's designed to be a reusable URL fetching class so feel free to update it if you need URL fetching elsewhere. It has a synchronous interface: in the future it may also have an async interface as well.

QRWebScraper:
------------------------

This class will probably only be used by QRRadarSubmissionService, as it is likely that any other service will have an actual API, but if anything else does need web scraping then this is the class to do it. This class wraps the whole process of creating a web page request, fetching the data, and parsing string values from the response using XPaths. The `fetch:` method is synchronous, and includes a network request, so run this one on a background thread.

PasswordStoring:
------------------------

Currently this functions as a bridge specifically between the Radar password field in the Mac UI and the Keychain. I haven't renamed it to QR yet since it probably wants its role rethinking a bit. We're going to need a reusable password saving object that can be used from any of the service configuration dialog boxes.

QRRadarWindowController:
------------------------

The Mac main window controller. This is responsible for starting off the submission process by creating a QRSubmissionController, and holding the window around until the submission is finished. This may change in the future (do we want the active submissions as app-level things?), although since I like the fact the window doesn't disappear until the submission is over, there isn't that much need to refactor it. Soon this class will gain a progress bar.

If `[QRRadarSubmissionService isAvailable]` returns NO when the window is opened, an error should be displayed.

It should handle displaying check boxes for activating services, and also remembering the last state of each checkbox. (It should also remember the last state of each popup menu.)

QRSettingsWindowController:
------------------------

The Mac class that handles the Settings window. It is responsible for displaying all the settings panels of each service in a nice tabbed interface, plus the QRMainSettingsViewController. How does it find the services? They register themselves in +load, remember? 

QRMainSettingsViewController:
------------------------

The view controller that displays the main settings, such as the global hot key, whether the app shows in the dock, and other such things.



Possible Tasks and Ideas
========================


New services: What about a Twitter service? A Tumbler service that blogs your radar report? Maybe a service to write all your Radars to a file on the file system? Having more services shouldn't be a problem, since if the user doesn't fill in login details in Setting then they won't appear as checkboxes on the New Radar window. For something like the file system writing one, we could have an "enabled" checkbox in Settings, so that 

New Radar features? That is, things like Configuration Profiles and Attached Files. We'd need to improve the QRRadar code to have fields for them, add them to the user interface and the window controller, then modify QRRadarSubmissionService to deal with them. Don't forget the point of QuickRadar is to remove the hassle from submitting bugs, so make anything like this optional --- if the user doesn't touch the UI widgets for files or configuration profiles, the submission should work and just not include them. A lot of this stuff requires some exploratory work in the web-based Radar, to see just how it behaves. UI-wise, for attached files, a file well would be great. Even better if the code can deal with the user pasting an image into that well, and creates a PNG to upload automatically.

Validation: work out precisely which Radar bug types require attached stuff, and use the validation methods in QRRadarSubmissionService to return sensible errors if the requirements aren't met.

We could investigate the iOS view of RadarWeb, as that allows you to submit crashes without attaching crash reports. If someone were to investigate what changes would be required to the web scraping to do this, then we could remove the file attaching requirements for those types in QuickRadar.

App features: I'd love a preference for whether the app displays in the Dock: personally I'd like it to, so I can command-tab to it, but I know some people prefer it not to. The bug report window should remember what options the user chose for the popup menus and default to those next time. We could automatically populate the text field with the Apple suggested headings (Summary, Steps to Reproduce, etc). Customisable font for the main field would be great (change it in Settings).

Sparkle: I plan to put that in at the last minute when I release version 1.0 as a binary release.

Unit tests: we don't have any! We should!

Password management: the class @secboffin contributed could be generalised and made available for use by the various Services (instead of being tied quite strongly to the Mac version of the Radar settings UI).

Developer documentation: this file gives a good outline of where I see the main app structure going, but we could also do with commenting the headers to be able to generate documentation. I prefer AppleDoc format for header documentation.

While I don't want to make this a Radar reading client yet (that's a big feature that'd require a fair bit of design work to make it useable, and it's better to get a solid app for submitting Radars before we move on), we could have an option in our menu for "Recently submitted", which just keeps the title and OpenRadar URL of the last few Radars submitted through the app (stored in user defaults), and lets you jump directly to the OpenRadar page for them.

We could have a system service to make a new Radar with the selected text: maybe useful for getting code snippets out of Xcode.


Notes
=====

Since we're not aiming for the Mac app store, we probably don't have to sandbox QuickRadar, but it might be worth thinking about what aspects of it would suffer if we did.

Currently the target version of MacOS is Lion, and the target version of iOS is 5. Since developers tend to move to the latest OS versions quite quickly, expect this to change quite soon after major releases, if features of the new OS makes coding QuickRadar easier.

Release schedule: I'm going to get version 1.0 out as soon as the refactoring is done, OpenRadar is in there, and it seems to not be buggy. After that, I suggest minor releases whenever bug fixes are made, and major releases when there are features that merit one: that is to say, no set schedule. After 1.0, I'll merge pull requests on the development branch first, and try to have master always correspond to the latest binary release.

Contributors: as I mentioned elsewhere, put your name and Twitter handle into Credits.rtf, so that you appear in the About box.

