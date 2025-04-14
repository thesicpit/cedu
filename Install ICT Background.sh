#!/bin/bash

# Define the URL for the .pkg file
pkg_url="https://www.twcs.catholic.edu.au/files/33326/twcs.gn1-1.0.pkg"

# Define the path to save the .pkg file
pkg_file="/tmp/twcs.gn1-1.0.pkg"

echo "Downloading ICT Background package from: $pkg_url"

# Download the .pkg file to /tmp
curl -L -o "$pkg_file" "$pkg_url"

# Verify the download was successful
if [ ! -f "$pkg_file" ]; then
  echo "Error: Download failed."
  exit 1
fi

echo "Download successful. Installing the .pkg..."

# Install the .pkg file
sudo installer -pkg "$pkg_file" -target /

# Check if the installation was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to install the .pkg."
  exit 1
fi

# Clean up by removing the downloaded .pkg file
rm "$pkg_file"
echo "ICT Background has been installed successfully and clean-up done."
