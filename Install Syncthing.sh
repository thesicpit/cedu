#!/bin/bash

# Define paths and variables
app_path="/Applications/Syncthing.app"
receipt_path="/Library/Receipts/com.syncthing-macos.pkg"
github_api_url="https://api.github.com/repos/syncthing/syncthing-macos/releases/latest"

# Function to get the latest release from GitHub
get_latest_release() {
  curl --silent "$github_api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Fetch the latest release version from GitHub
latest_version=$(get_latest_release)

if [ -z "$latest_version" ]; then
  echo "Error: Unable to fetch the latest Syncthing macOS version."
  exit 1
fi

echo "Latest version: $latest_version"

# Check the installed version if Syncthing is already installed
if [ -d "$app_path" ]; then
  if [ -f "$receipt_path" ]; then
    installed_version=$(cat "$receipt_path")
    echo "Installed version: $installed_version"
  else
    echo "No receipt found. Assuming no installed version."
    installed_version="none"
  fi
else
  echo "Syncthing is not installed."
  installed_version="none"
fi

# Compare the installed version with the latest version
if [ "$installed_version" == "$latest_version" ]; then
  echo "Syncthing is already up to date (version $installed_version). No installation needed."
  exit 0
else
  echo "Newer version available: $latest_version (Installed: $installed_version). Proceeding with installation."
fi

# Construct the download URL for the latest .dmg file
dmg_url=$(curl -s "$github_api_url" | grep "browser_download_url.*dmg" | cut -d '"' -f 4)

if [ -z "$dmg_url" ]; then
  echo "Error: Could not find the .dmg download URL."
  exit 1
fi

echo "Downloading from: $dmg_url"

# Download the latest .dmg file to /tmp
dmg_file="/tmp/syncthing-latest.dmg"
curl -L -o "$dmg_file" "$dmg_url"

# Verify the download was successful
if [ ! -f "$dmg_file" ]; then
  echo "Error: Download failed."
  exit 1
fi

echo "Download successful. Mounting the .dmg..."

# Mount the .dmg file
mount_info=$(hdiutil attach "$dmg_file" -nobrowse)

# Extract the mounted volume name
volume_name=$(echo "$mount_info" | grep "/Volumes/" | awk '{print $3}')

if [ -z "$volume_name" ]; then
  echo "Error: Could not mount the .dmg file."
  exit 1
fi

echo "Mounted at: $volume_name"

# Copy Syncthing.app to /Applications
if [ -d "$volume_name/Syncthing.app" ]; then
  echo "Installing Syncthing..."
  rm -rf "$app_path"  # Remove the old version if it exists
  cp -R "$volume_name/Syncthing.app" /Applications/
else
  echo "Error: Syncthing.app not found in the mounted volume."
  exit 1
fi

# Eject the mounted volume
hdiutil detach "$volume_name"

# Clean up by removing the downloaded .dmg file
rm "$dmg_file"

# Write the installed version to the package receipt for future comparisons
echo "$latest_version" > "$receipt_path"

echo "Syncthing has been installed successfully (version $latest_version) and clean-up done."
