#!/bin/bash

userName=$(/bin/ls -la /dev/console | /usr/bin/cut -d " " -f 4)
macModel=$(/usr/sbin/sysctl -n hw.model)

setModel='STG-MBA'


computerName="$userName-$setModel"

# Set the ComputerName, HostName and LocalHostName
/usr/sbin/scutil --set ComputerName "$computerName"
/usr/sbin/scutil --set HostName "$computerName"
/usr/sbin/scutil --set LocalHostName "$computerName"

## Create dummy receipt to mark complete
touch /Library/Receipts/com.stg.renameComplete.bom

## Update Inventory
/usr/local/bin/jamf setComputerName -name $computerName
/usr/local/bin/jamf recon -endUsername $userName
/usr/local/bin/jamf recon

dscacheutil -flushcache
q`qq`