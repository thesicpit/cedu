#!/bin/bash

# Define the GitHub API URL for the latest release of Input Leap
github_api_url="https://api.github.com/repos/input-leap/input-leap/releases/latest"

# Step 1: Get the latest version number from GitHub
latest_version=$(curl -s "$github_api_url" | grep '"tag_name":' | cut -d '"' -f 4)

# Step 2: Check if the latest version is found
if [ -z "$latest_version" ]; then
  echo "Error: Could not find the latest version on GitHub."
  exit 1
fi

echo "Latest version on GitHub: $latest_version"

# Step 3: Check the installed version on the target device
app_path="/Applications/Input Leap.app"
receipt_path="/Library/Receipts/com.input-leap.pkg"

if [ -d "$app_path" ]; then
  # Try to get the installed version
  if [ -f "$receipt_path" ]; then
    installed_version=$(cat "$receipt_path")
    echo "Installed version: $installed_version"
  else
    echo "No receipt found. Assuming no installed version."
    installed_version="none"
  fi
else
  echo "Input Leap is not installed."
  installed_version="none"
fi

# Step 4: Compare versions
if [ "$installed_version" == "$latest_version" ]; then
  echo "Input Leap is already up to date (version $installed_version). No installation needed."
  exit 0
else
  echo "Newer version available: $latest_version (Installed: $installed_version). Proceeding with installation."
fi

# Step 5: Determine architecture and select the appropriate .dmg file
arch=$(uname -m)
if [ "$arch" == "arm64" ]; then
  dmg_url=$(curl -s "$github_api_url" | grep "browser_download_url.*AppleSilicon.dmg" | cut -d '"' -f 4)
else
  dmg_url=$(curl -s "$github_api_url" | grep "browser_download_url.*x86_64.dmg" | cut -d '"' -f 4)
fi

# Step 6: Check if the dmg_url is found
if [ -z "$dmg_url" ]; then
  echo "Error: Could not find a valid .dmg file for the current architecture."
  exit 1
fi

echo "Downloading Input Leap from: $dmg_url"

# Step 7: Download the .dmg file to /tmp
dmg_file="/tmp/input_leap_latest.dmg"
curl -L -o "$dmg_file" "$dmg_url"

# Step 8: Mount the .dmg file
echo "Mounting DMG file..."
mount_info=$(hdiutil attach "$dmg_file" -nobrowse)

# Debugging output: Show the mount info
echo "Mount info:"
echo "$mount_info"

# Step 9: Extract the mounted volume name from mount_info
volume_name=$(echo "$mount_info" | grep "/Volumes/" | awk '{print substr($0, index($0,$3))}')

if [ -z "$volume_name" ]; then
  echo "Error: Could not find the mounted volume for Input Leap."
  exit 1
fi

# Trim any whitespace that might affect the path
volume_name=$(echo "$volume_name" | xargs)

echo "Mounted at: $volume_name"

# Step 10: Remove the old version of Input Leap from /Applications
if [ -d "$app_path" ]; then
  echo "Removing old version of Input Leap..."
  rm -rf "$app_path"
fi

# Step 11: Locate any `.app` within the mounted volume and copy it
echo "Looking for an .app in mounted volume..."
app_source=$(find "$volume_name" -name "*.app" -type d)

if [ -z "$app_source" ]; then
  echo "Error: No .app file found in the mounted volume."
  exit 1
fi

echo "Installing Input Leap from: $app_source"
cp -R "$app_source" /Applications/

# Step 12: Eject the mounted volume
hdiutil detach "$volume_name" -quiet

# Step 13: Clean up by removing the downloaded .dmg file
rm "$dmg_file"

# Step 14: Write the version to a package receipt file for future comparisons
echo "$latest_version" > "$receipt_path"

echo "Input Leap has been installed successfully (version $latest_version)."
