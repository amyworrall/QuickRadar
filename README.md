QuickRadar
==========

Mac app to simplify posting bug reports to Apple's Radar bug tracking system. It provides a global hotkey to open a window in which to enter a bug report, which can be easily submitted to Apple.

Status
======

The app is currently VERY rough-and-ready. It stores your username/password in NSUserDefaults in plain text. It has very little error handling worth speaking of. It almost certainly can't deal with any Radar of the type where you have to upload a crash report. You can't change the hotkey to invoke it. **Use at your own risk!**

The code is in just as bad a state. The web scraping is done in one big method which chains xpaths together to plot a course through the web site, and currently it spits out all the logs I was using while trying to get something that could post to Radar.

That said, I do plan to develop it a lot more. I'd also welcome any help and contributions. I'm sharing it now because I've reached the stage where it can post Radars.

Roadmap
=======

I hope to get it doing the following things:

* Also posting to OpenRadar
* Definable shortcut key
* Storing password in Keychain
* Customise the lists of components etc to display your favourites at the top
* Uploading config information for crash reports
* Error handling, incorrect password dialog etc
* And more! Maybe future versions will let you browse your submitted Radars too.