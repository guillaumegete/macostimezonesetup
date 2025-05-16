#!/bin/bash
# Displays a dialog to change the Mac's time zone. Must be launched from Jamf Self Service.
# G. Gete - 04/11/2025
# v1.1

# This script requires SwiftDialog. Following code provided by Adam Codega here: 
# https://github.com/acodega/swiftDialogScripts/blob/main/dialogCheckFunction.sh

function dialogCheck(){
	# Get the URL of the latest PKG From the Dialog GitHub repo
	dialogURL=$(curl --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	# Expected Team ID of the downloaded PKG
	expectedDialogTeamID="PWA5E9TQ59"
	
	# Check for Dialog and install if not found
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		echo "Dialog not found. Installing..."
		# Create temporary working directory
		workDirectory=$( /usr/bin/basename "$0" )
		tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		# Download the installer package
		/usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
		# Verify the download
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		# Install the package if Team ID validates
		if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
			/usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
			# else # uncomment this else if you want your script to exit now if swiftDialog is not installed
			# displayAppleScript # uncomment this if you're using my displayAppleScript function
			# echo "Dialog Team ID verification failed."
			# exit 1
		fi
		# Remove the temporary working directory when done
		/bin/rm -Rf "$tempDirectory"  
	else echo "Dialog found. Proceeding..."
	fi
}

dialogCheck

# Get the current time zone and associated continent

currentTimeZone=$(systemsetup -gettimezone | cut -c 12-)
listTimezones=$(systemsetup -listtimezones | grep -v Time | tr -d " " | tr "\n" ",")
currentContinent=$(echo "$currentTimeZone" | awk -F "/" '{print $1}')

echo "Current continent: $currentContinent" # May be used in a future version

# Set the icon based on the continent — because why not.

case "$currentContinent" in
	"Africa")
		zoneIcon="globe.europe.africa.fill"
	;;
	"America")
		zoneIcon="globe.americas.fill"
	;;
	"Antarctica")
		zoneIcon="globe"
	;;
	"Arctic")
		zoneIcon="snowflake.circle,animation=pulse.bylayer"
	;;
	"Asia")
		zoneIcon="globe.asia.australia.fill"
	;;
	"Atlantic")
		zoneIcon="globe.europe.africa.fill"
	;;
	"Australia")
		zoneIcon="globe.asia.australia.fill"
	;;
	"Europe")
		zoneIcon="globe.europe.africa.fill"
	;;
	"Indian")
		zoneIcon="globe.central.south.asia.fill"
	;;
	"Pacific")
		zoneIcon="globe.asia.australia.fill"
	;;
esac

# Display the dialog

newTimezone=$(dialog --selectitle "Time Zone:" \
--selectvalues "$listTimezones" \
--selectdefault "$currentTimeZone" \
--icon "sf=$zoneIcon,color=green" --overlayicon "sf=clock.fill,color=green,bgcolor=none" \
--message "Select your new time zone from the list below.  \n\n**Current time zone: $currentTimeZone**" \
--bannertitle "Change Time Zone" \
--bannerheight 64 \
--bannerimage colour=green \
--button1text "Apply" \
--button2text "Cancel" | grep "SelectedOption" | awk -F " : " '{print $NF}' | tr -d '"')

case $? in
	0)
		echo "OK clicked"
		echo "New time zone: $newTimezone"
		systemsetup -settimezone "$newTimezone"
	;;
	2)
		echo "Operation canceled (Button 2)"
		exit 0
	;;
esac
exit 0
