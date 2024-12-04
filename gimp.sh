#!/bin/bash

# Define the base URL
base_url="https://mirror.freedif.org/gimp/pub/gimp/"

# Step 1: Get the latest version folder
latest_version_folder=$(curl -s "$base_url" | \
  grep -o 'href="v[0-9]\+\.[0-9]\+/"' | \
  sed 's/href="//; s/"//' | \
  sort -V | \
  grep -v 'v2\.99' |  # Exclude v2.99
  tail -n 1)

if [ -z "$latest_version_folder" ]; then
  echo "Error: Could not find the latest version folder."
  exit 1
fi

# Construct the URL for the osx folder
osx_folder_url="${base_url}${latest_version_folder}osx/"

echo "Latest version folder URL: $osx_folder_url"

# Step 2: Find the latest .dmg file in the osx folder
dmg_file=$(curl -s "$osx_folder_url" | \
  grep -o 'href="gimp-[0-9]\+\.[0-9]\+\.[0-9]\+-[a-z]*[0-9]*\.dmg"' | \
  sed 's/href="//; s/"//' | \
  sort -V | \
  tail -n 1)

if [ -z "$dmg_file" ]; then
  echo "Error: Could not find the .dmg file for the latest version."
  exit 1
fi

# Construct the download URL
download_url="${osx_folder_url}${dmg_file}"

echo "Downloading the latest GIMP from: $download_url"

# Step 3: Download the latest .dmg file to /tmp
curl -L -o "/tmp/$dmg_file" "$download_url"

# Step 4: List mounted volumes before mounting
echo "Mounted volumes before attempting to mount the .dmg file:"
ls /Volumes

# Step 5: Mount the .dmg file
mount_output=$(hdiutil attach "/tmp/$dmg_file" -nobrowse -quiet 2>&1)

# Log the mount output
echo "Mount output: $mount_output"

# Step 6: List mounted volumes after mounting
echo "Mounted volumes after attempting to mount the .dmg file:"
ls /Volumes

# Step 7: Find the mounted volume name containing "GIMP"
volume_name=$(ls /Volumes | grep "GIMP" | head -n 1)

# Check if the mounted volume was found
if [ -z "$volume_name" ]; then
  echo "Error: Could not find the mounted volume for GIMP."
  echo "Mount output: $mount_output"
  exit 1
fi

echo "Mounted at: $volume_name"

# Step 8: Copy GIMP.app to /Applications
if [ -d "/Volumes/$volume_name/GIMP.app" ]; then
  echo "Copying GIMP.app to /Applications..."
  cp -R "/Volumes/$volume_name/GIMP.app" /Applications/
else
  echo "Error: GIMP.app not found in mounted volume."
  exit 1
fi

# Step 9: Eject the mounted volume
echo "Ejecting the mounted volume..."
hdiutil detach "/Volumes/$volume_name" -quiet

# Step 10: Clean up by removing the downloaded .dmg file
rm "/tmp/$dmg_file"

echo "GIMP has been installed successfully."

#touch /Library/Receipts/com.gimp.org.v2.10.bom
touch /Library/Receipts/$4
