#!/bin/bash

#
# to test, sudo touch -t 8001031305 /Library/Managed\ Installs/Cache/cachedtemp
# to re-run test, rm /tmp/sup_lastrun
#

## Checking which user is logged in
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

## Number of allowed delays
maxdelay=3

## Current date and time
now=$(date +%Y%m%d%H%M)

## Checking if SUP ran in the past two hours
if [ -f /tmp/sup_lastrun ]; then
   lastrun=$(cat /tmp/sup_lastrun)
else
   lastrun="201800000000"

fi

timepassed=`expr $now - $lastrun`
if [ "$timepassed" -lt "120" ]; then
	echo "SUP did run in the last 2 hours ($timepassed min ago). Updating inventory and Stop."
    jamf recon
	exit 0
else
	echo "SUP did not run in the last 2 hours ($timepassed min ago). STARTING...."
	echo $now > /tmp/sup_lastrun
fi


## Defining source folder to check for updates
SOURCE="/Library/Updates"
WAITINGUPDATES=0

## Do not run if no user is logged in
usercount=$(who | grep console | grep -v _mbsetupuser | wc -l | sed 's/ //g')

if [ "$usercount" == "0" ]; then
	echo "SUP: no user logged in. Stopping script."
	exit 0
fi


## Check for munki updates
list=$(ls "/Library/Managed Installs/Cache/")
for folder in $list

do
	echo $folder
	if [[ $(find "/Library/Managed Installs/Cache/$folder" -mtime +3 -print) ]]; then
  		echo "SUP: !!!!!! File $folder exists and is older than 3 days"
  		WAITINGUPDATES=1
  	else
  		echo "SUP: File $folder exists and is newer than 3 days"
	fi
done

if [ "$WAITINGUPDATES" == "0" ]; then
	echo "SUP: Everything is fine. Running recon"
  	# reset delay counter
    defaults write /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount -int 0
    jamf recon
	  exit 0
else

	echo "SUP: show dialog"

## JamfHelper window
	Button=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Pending Updates" \
-description "You have not installed last weeks software updates. These updates are important to keep your mac safe and secure. Please press 'Go To Safety' to log out and install these software updates." \
-icon '/Applications/Managed Software Center.app/Contents/Resources/Managed Software Center.icns' \
-button1 "Go To Safety" \
-button2 "Stay Unsafe" \
-timeout 15 -countdown \
-defaultButton 1 \
-cancelButton 0)

	#Button=$( echo "$SWUDiag" | awk 'NR==1{print $0}' )

	echo $Button

	if [[ "$Button" == "0" ]]; then
		echo "SUP: Bootstrapping munki"
		touch /Users/Shared/.com.googlecode.munki.checkandinstallatstartup

    # check delay counter
    	current_delays=$(defaults read /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount)
        new_delay_count=$(expr $current_delays + 1)
		defaults write /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount -int $new_delay_count

		echo "SUP: logout"
		osascript -e 'tell application "loginwindow" to «event aevtrlgo»'
		killall jamfHelper
	elif [[ "$Button" == "2" ]]; then
    	echo "user clicked Stay Unsafe..."
      # check delay counter
    	current_delays=$(defaults read /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount)

        # added on 28-12-2018
        if [ -z $current_delays ]; then
			current_delays=0
		fi

			echo updates are currently delayed by $current_delays times.
			echo updates can be delayed by $maxdelay times max.


      new_delay_count=$(expr $current_delays + 1)
			defaults write /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount -int $new_delay_count
      echo "telling JAMF about the amount of delays"
      jamf recon
            if  [ "$current_delays" -eq "$maxdelay" ]; then
				echo "updates have been delayed by the maximum amount of times. We're going to start with the warnings"
jamf policy -event update_alert
			fi

			if  [ "$current_delays" -gt "$maxdelay" ]; then
				echo "updates have not been installed yet. Time for MAYHEM!"

echo "removing SplashBuddyDone file so SplashBuddy can start"
rm -rf "/Users/${loggedInUser}/Library/Containers/io.fti.SplashBuddy/Data/Library/.SplashBuddyDone"
rm -rf "/Library/Application Support/SplashBuddy"

echo "Calling policy to install and run SplashBuddy"
## Kicking of the SplashBuddy Policy
jamf policy -event outofdate
sleep 1
echo "setting volume to maximum"
osascript -e "set Volume 10"

			else
				echo "We'll allow to delay updating some more"
			fi

			exit 0
	fi

	echo "SUP: done"
fi
exit 0
