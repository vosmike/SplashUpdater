#!/bin/bash

## Checking for contents of Update Cache folder
if [ -z "$(ls -A /Library/Managed\ Installs/Cache/)" ]; then
   echo "Updates have been installed, resetting counter"
	# reset delay counter
    defaults write /Library/Application\ Support/JAMF/com.sup.plist updatedelaycount -int 0
    jamf recon
else
   echo "Updates have not been installed yet, sending a warning"
	"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType hud -title Update Alert -description "You chose to 'Stay Unsafe' and have reached your maximum amount of delays.
If you choose to 'Stay Unsafe' again, we will install them for you. You can install updates in Managed Software Center." -alignDescription left -icon '/Applications/Managed Software Center.app/Contents/Resources/Managed Software Center.icns' -timeout 15 -countdown -countdownPrompt This window will close in: -alignCountdown center

fi
## Bootstrapping Munki
touch /Users/Shared/.com.googlecode.munki.checkandinstallatstartup

exit 0
