#!/bin/bash
# Affiche un dialogue permettant de modifier le fuseau horaire du Mac. Doit être lancé depuis le Self Service de Jamf.
# G. Gete - 11/04/2025
# v1.1

# Obtention du fuseau et du continent associé

currentTimeZone=$(systemsetup -gettimezone | cut -c 12-)
listTimezones=$(systemsetup -listtimezones | grep -v Time | tr -d " " | tr "\n" ",")
currentContinent=$(echo "$currentTimeZone" | awk -F "/" '{print $1}')

echo "Continent actuel : $currentContinent" # Sera peut-être utilisé dans une future version

# On définit l'icône affichée en fonction du continent, parce que why not.

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

# Affichage du dialogue

newTimezone=$(dialog --selectitle "Fuseau horaire :" \
--selectvalues "$listTimezones" \
--selectdefault "$currentTimeZone" \
--icon "sf=$zoneIcon,color=green" --overlayicon "sf=clock.fill,color=green,bgcolor=none" \
--message "Sélectionnez votre nouveau fuseau horaire dans la liste ci-dessous.  \n\n**Fuseau horaire actuel : $currentTimeZone"** \
--bannertitle "Modifier le fuseau horaire" \
--bannerimage "/Library/Application Support/BPCE/Images/banner_bpce.png" \
--button1text "Appliquer" \
--button2text "Annuler" | grep "SelectedOption" | awk -F " : " '{print $NF}' | tr -d '"')

case $? in
	0)
		echo "OK appuyé"
		echo "Nouveau fuseau horaire : $newTimezone"
		systemsetup -settimezone "$newTimezone"
		
	;;
	2)
		echo "Opération annulée (Bouton 2)"
		exit 0
	;;
esac
exit 0
