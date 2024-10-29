#!/bin/bash 
#serialNumber=`system_profiler SPHardwareDataType | grep "Serial Number" | sed 's/^[^:]*: //'` 

#/usr/sbin/systemsetup -setcomputername $serialNumber 
#/usr/sbin/systemsetup -setlocalsubnetname $serialNumber 
#/usr/sbin/scutil --set HostName $serialNumber

#gets current logged in user
getUser=$(ls -l /dev/console | awk '{ print $3 }')

# Get the Serial Number of the Machine
sn=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

#gets named
firstName=$(finger -s $getUser | head -2 | tail -n 1 | awk '{print tolower($2)}')
lastName=$(finger -s $getUser | head -2 | tail -n 1 | awk '{print tolower($3)}')
computerName=$firstName.$lastName
hostName=$firstName"-"$lastName

#set all the names in all the places
scutil --set ComputerName "$computerName"
sleep 3
scutil --set HostName "$hostName"
sleep 3
scutil --set LocalHostName "$hostName"
sleep 3

/usr/bin/dscacheutil -flushcache
