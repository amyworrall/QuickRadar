QuickRadar
==========

Mac app to simplify posting bug reports to Apple's Radar bug tracking system. It provides a global hotkey to open a window in which to enter a bug report, which can be easily submitted to Apple.

More info at http://www.quickradar.com/

Status
======

The app is currently VERY rough-and-ready. It has very little error handling worth speaking of. It almost certainly can't deal with any Radar of the type where you have to upload a crash report. You can't change the hotkey to invoke it. **Use at your own risk!**

The code is in just as bad a state. The web scraping is done in one big method which chains xpaths together to plot a course through the web site, and currently it spits out all the logs I was using while trying to get something that could post to Radar.

That said, I do plan to develop it a lot more. I'd also welcome any help and contributions. I'm sharing it now because I've reached the stage where it can post Radars.

Using QuickRadar
================

Build and run the app. It is meant to run in the background, and does not open any windows at launch, it only displays a menubar icon.

First, choose "Login Details…" from the QuickBug menu. In there, fill in your username and password for Apple's web-based bug reporter. Make sure you get them right!

To invoke QuickRadar, press command-option-control-space. A window will pop up for you to fill in the details of your radar. At the moment, don't choose any Classification that would make the bug reporter require a file upload (such as Crash/Hang/Data Loss), because QuickRadar doesn't support them yet, nor does it have any error handling worth speaking of.

Once you've entered the details, hit Submit. Sadly this bit is anything but quick: in the background, QuickRadar has to log in to the bug reporter web page, fetch the New Problem page, fill it in, and submit the form. However, you can go and do something else while that's happening. Once it is done you'll get a growl notification.

Roadmap
=======

I hope to get it doing the following things:

* Also posting to OpenRadar
* Definable shortcut key
* Customise the lists of components etc to display your favourites at the top
* Uploading config information for crash reports
* Error handling, incorrect password dialog etc
* And more! Maybe future versions will let you browse your submitted Radars too.

Contributors
============

A list of contributors can be found in the QuickBug/en.lproj/Credits.rtf file. This file also displays in the About window when the app is running. If you contribute, feel free to add your name and Twitter handle there.