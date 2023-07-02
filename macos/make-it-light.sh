#!/bin/bash

# Script to toggle between dark and light mode for a specific app
# Ensure that two command-line arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <app_bundle_identifier> <mode>"
    exit 1
fi

# Get the application's bundle identifier
app_bundle_identifier=$(osascript -e "id of app \"$1\"")

# Check if the application exists
if [ -z "$app_bundle_identifier" ]; then
    echo "Application not found: $1"
    exit 1
fi

# Determine the mode
mode=$2

# Validate the mode
if [ "$mode" != 'dark' ] && [ "$mode" != 'light' ]; then
    echo "Invalid mode: $mode. Supported modes are 'dark' or 'light'."
    exit 1
fi

# Set the app's appearance mode
if [ "$mode" == 'dark' ]; then
    # Set the app to dark mode
    defaults write "$app_bundle_identifier" NSRequiresAquaSystemAppearance -bool NO
    echo "Dark mode enabled for $1"
else
    # Set the app to light mode
    defaults write "$app_bundle_identifier" NSRequiresAquaSystemAppearance -bool YES
    echo "Light mode enabled for $1"
fi

exit 0

