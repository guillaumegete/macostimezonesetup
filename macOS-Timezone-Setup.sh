#!/bin/bash
# Displays a dialog to change the Mac's time zone. Must be launched from Jamf Self Service.
# G. Gete - 16/05/2025
# v1.2


# bool function to test if the user is root or not (POSIX only)
is_user_root ()
{
	[ "$(id -u)" -eq 0 ]
}

if is_user_root; then
	echo 'You are the almighty root!'
	# You can do whatever you need...
else
	echo 'You are just an ordinary user.' >&2
	exit 1
fi


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

# Language support based on work from SecondSonConsulting.
# https://github.com/SecondSonConsulting/Renew/blob/d376f2f69aa17cd058281ae92cfcab4df79cb5e4/Renew.sh

#########################
#	Language Support	#
#########################

consoleUser=$(stat -f%Su /dev/console)

languageList=( $(sudo -u "$consoleUser" defaults read .GlobalPreferences AppleLanguages) )

languageChoice=${languageList[1]:1:2}

echo "Language identified: $languageChoice"

#To add additional language support, create a case statement for the 2 letter language prefix
#For example: "en" for english or "es" for espaniol
#Then enter the desired text for those strings.

case "$languageChoice" in
	fr)
		#Define script default messaging FRENCH
		dialogTitle="Fuseau horaire :"
		bannerTitleLoc="Modifier le fuseau horaire"
		messagePart1="Sélectionnez votre nouveau fuseau horaire dans la liste ci-dessous."
		messagePart2="Fuseau horaire actuel :"
		button1Text="Appliquer"
		button2Text="Annuler"
	;;
	*)
		##English is the default and fallback language
		
		#Define script default messaging ENGLISH
		dialogTitle="Time zone:"
		bannerTitleLoc="Change Time zone"
		messagePart1="Select your new time zone from the list below."
		messagePart2="Current time zone:"
		button1Text="Apply"
		button2Text="Cancel"
	;;
esac


# Get the current time zone and associated continent

currentTimeZone=$(systemsetup -gettimezone | cut -c 12-)
listTimezones=$(systemsetup -listtimezones | grep -v Time | tr -d " " | tr "\n" ",")
currentContinent=$(echo "$currentTimeZone" | awk -F "/" '{print $1}')

echo "Current continent: $currentContinent" #

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

newTimezone=$(dialog --selectitle "$dialogTitle" \
--selectvalues "$listTimezones" \
--selectdefault "$currentTimeZone" \
--icon "sf=$zoneIcon,color=green" --overlayicon "sf=clock.fill,color=green,bgcolor=none" \
--message "$messagePart1  \n\n**$messagePart2 $currentTimeZone**" \
--bannertitle "$bannerTitleLoc" \
--bannerheight 64 \
--bannerimage colour=green \
--button1text "$button1Text" \
--button2text "$button2Text")
dialogExitCode=$?	

newTimezone=$(echo "$newTimezone" | grep "SelectedOption" | awk -F " : " '{print $NF}' | tr -d '"')

case ${dialogExitCode} in
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
