#!/bin/bash

##
## sets the desktop using `desktoppr`
##

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# set the path to the desktop image file here
picturepath="/Library/Desktop Pictures/grinch-nova.png"


# verify the image exists
if [[ ! -f "$picturepath" ]]; then
    echo "no file at $picturepath, exiting"
    exit 1
fi

# verify that desktoppr is installed
desktoppr="/usr/local/bin/desktoppr"
if [[ ! -x "$desktoppr" ]]; then
    echo "cannot find desktoppr at $desktoppr, exiting"
    exit 1
fi

# get the current user
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# test if a user is logged in
if [[ -n "$loggedInUser" ]]; then
    # set the desktop for the user
    uid=$(id -u "$loggedInUser")

    if [[ "$(sw_vers -buildVersion)" > "21" ]]; then
        # behavior with sudo seems to be broken in Montery
        # dropping the sudo will result in a warning that desktoprr seems to be
        # running as root, but it will still work
      sudo launchctl asuser "$uid" "$desktoppr" "$picturepath"
    else
        sudo -u "$loggedInUser" launchctl asuser "$uid" "$desktoppr" "$picturepath"
    fi
else
    echo "no user logged in, no desktop set"
fi

