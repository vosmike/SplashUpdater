# SplashUpdater
## Not forcing updates, kinda.
As requested by a few after reading this [blog](https://www.jamf.com/blog/not-forcing-updates-kinda/).

Built upon the popular [SplashBuddy](https://github.com/Shufflepuck/SplashBuddy) onboarding app and [Munki](https://github.com/munki/munki)
It will allow you to:

- let users decide when updates will be installed
- decide over how long a period these updates have to be installed (default is 3 days)
- Show content to your liking using Splashbuddy

### Start with WHY
Munki is an awesome tool to update applications on your Mac clients. Showing the end user a window with available updates.
However, the users can still choose to close the window and carry on with their work. This sometimes leads to Mac's being out of date for several weeks and sometimes, months.
This of course is a huge security risk.
As we do not like to force updates upon people, we had to come up with something that will explain the user what is happening and why it is important to update.
Warning them that if they do not update, they force us to do it for them. Which might be in a very inconvenient time.

### HOW
Use Jamf Pro, Munki and SplashBuddy to build a framework that puts you back in control, the nice way.

###WHAT
SplashUpdater

### Quick Start
This is build to work with Jamf Pro, Munki and SplashBuddy. Creative minds would probably be able to make it work for other solutions. Feel free to do so.

#### Scripts and Extensions Attributes
Upload the scripts and EA's to your JAMF Pro instance.
You can find the files at the top of this page.

#### Smart Groups
Create the following smart groups
+ **Name**: Update Monitor
	*Criteria*
	Munki update >3 days old (Extension Attribute)
	Value: **'is'**
	1

+ **Name**: One click away from MAYHEM!
	*Criteria*
	Get Delay Amount (Extension Attribute)
	Value **'is'**
	3

#### Policies
Create the following policies
+ **Name**: Update alert >3 days old
	Trigger: Ongoing
	Run the script *'Munki update alert'* with priority '**After**'
	Scope: Update Monitor (Created Smart Group)

+ **Name**: Final Warnings
  Trigger: Check-in, update_alert
  Run the script *'Final_Warnings'* with priority '**After**'
  Scope: One click away from MAYHEM!

+ **Name**: SplashUpdater
  Trigger: outofdate
  Run two scripts *'01sb_ghost_pkg'* with priority '**Before**'. And *'z02sb_ghost_pkg'* with priority '**After**''(courtesy of @ftiff)
  Install SB_Updates.pkg
  Scope: Update Monitor

#### How it works

##### Step one
Munki will cache all available updates in `/Library/Managed Installs/Cache`.
The script will look for contents of this folder and how long since they've been there.
If this is longer than 3 days, the value of `WAITINGUPDATES` will change to '1'.
This will put the Mac in the Smart Group 'Update Monitor'.

##### Step two
Once in this Smart Group, the user will start receiving warnings about pending updates and is given a choice to 'Go to Safety' or 'Stay Unsafe'. This is triggered by the 'Update alert >3 days old' policy.
Choosing 'Stay Unsafe' will add a value of '1' to the counter. Once this counter reaches the amount of '3', the maximum has been reached.
This warning is poping up every two hours.
> User hard at work, no time to update at the first warning.

![](https://www.dropbox.com/s/9055cx0wpsn7yp4/update_message.gif?raw=1)

##### Step three
The Mac is now moved to the Smart Group 'One click away from MAYHEM!'.
A final warning is given to the user. Which in it's turn is triggered by the policy 'Final Warnings'.
If they choose to 'Stay Unsafe' again, SplashBuddy takes over.
> After three chances to install the updates, the final warnings policy will spam the user ever Check-in.

![](https://www.dropbox.com/s/kbmpwoww3glnwyy/last_warning.png?raw=1)


##### Step four
The final policy 'SplashUpdater' kicks off.
Everything will force quit, the volume will be set to MAX and SplashBuddy will launch with Y.M.C.A. blasting through the headset or speakers.
The scripts within this policy are there to make sure the user can close SplashBuddy. The only way to close it however, is to log the user out.
As Munki is bootstrapped to the login window, updates will run immediately and will restart the Mac if needed.
> We've had enough, time to tell the user it took to long. Fun starts.

![](https://www.dropbox.com/s/rvzbs377mj1l776/ymca_in_yo_face.gif?raw=1)

### Special thanks
As I wouldn't have been able to do this without SplashBuddy, I would like to thank Francois (@ftiff) and Damien (@Ethenyl).
And as I'm not that great at scripting, a huge thanks to Sander Schram (@sanderschram on MacAdmins Slack) on helping me out on the scripting side.

## Disclaimer
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
