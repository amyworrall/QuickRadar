Config Folder
-------------

Some services, such as app.net and Twitter, require an API key per app. These keys aren't meant to be distributed, so the open source version of QuickRadar doesn't include them. If you're compiling QuickRadar from source, you can of course register your own API keys with the appropriate services. The required files are listed below.


app.net
-------

A file called `AppDotNetConfig.plist`, containing two keys, `clientID` (which should be set to the client ID you register with app.net) and `redirectURI`. The latter should be: quickradar://appdotnetauth


Twitter
-------