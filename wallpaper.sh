#!/bin/bash

###################################################################### 
# Copyright (C) 2023  Nitestryker 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
###################################################################### 

# Revision 3.5 (October 2023)

# Enhancements:
# - Restored the dialog window for an improved user experience.
# - Addressed and resolved issues related to conditional statements, enhancing script reliability.
# - Improved screen resolution detection to prevent downloaded images from being cut off at the top.

# Revision 3.4
# 
# Enhancements:
# - Introduced a visually appealing colored banner at the script's startup.
# - Temporarily removed the dialogue window with plans to reintroduce it in a future release upon issue resolution.

# Revision 3.3 
# 
# Improvements:
# - Conducted bug fixes, addressing minor issues to enhance script stability.

# Revision 3.2
# 
# New Features:
# - Implemented screen resolution detection to dynamically set the DESIRED_RESOLUTION variable.
# - Added download statistics to provide insights into the download process.
# - Resolved an issue related to calculating downloaded images, ensuring accurate tracking.

# Revision 3.1
# 
# Functionalities:
# - Introduced the capability to calculate MD5 hashes for downloaded images.
# - Established a mechanism to store MD5 hashes in the download_history.txt file, replacing previous URL-based tracking.
# - Implemented a check in the script to skip downloads of images already present in the download history.

# Revision 3
# 
# Feature Additions:
# - Introduced user-defined wallpaper resolution handling.
# - Implemented a download history feature to record and manage downloaded wallpapers.
# - Enhanced the script with the ability for users to choose between random and keyword-based wallpaper downloads.

# Define color codes
HEADER="\033[95m"
OKBLUE="\033[94m"
OKGREEN="\033[92m"
WARNING="\033[93m"
FAIL="\033[91m"
ENDC="\033[0m"
BOLD="\033[1m"
UNDERLINE="\033[4m"

# Script Title 
backtitle="Wallpaper Downloader"
title="Wallpaper Downloader"

# Get the current logged-in user
user=$(whoami)
# Define the directory where wallpapers will be stored
WALLPAPER_DIR="/home/${user}/Pictures"

# Detect screen resolution and set DESIRED_RESOLUTION
SCREEN_RESOLUTION=$(xrandr | awk '/\*/ {print $1}' | sed 's/x/*/g')
DESIRED_RESOLUTION="$SCREEN_RESOLUTION"

# Path to the download history file
DOWNLOAD_HISTORY_FILE="$WALLPAPER_DIR/download_history.txt"

# Function to download the wallpaper with a specific keyword or at random
download_wallpaper() {
    # Generate a unique filename based on the current timestamp
    UNIQUE_FILENAME="wallpaper_$(date +'%Y%m%d%H%M%S').jpg"

    if [ "$DOWNLOAD_MODE" == "random" ]; then
        # Download a random image from Unsplash
        IMAGE_URL=$(curl -Ls -w %{url_effective} -o /dev/null "https://source.unsplash.com/random/$DESIRED_RESOLUTION")
    elif [ "$DOWNLOAD_MODE" == "keyword" ]; then
        # Download an image with the specified keyword
        IMAGE_URL=$(curl -Ls -w %{url_effective} -o /dev/null "https://source.unsplash.com/featured/$DESIRED_RESOLUTION/?$KEYWORD")
    else
        echo "Invalid download mode: $DOWNLOAD_MODE"
        return 1
    fi

    # Calculate the MD5 hash of the image
    IMAGE_HASH=$(curl -Lf "$IMAGE_URL" | md5sum | awk '{print $1}')

    # Check if the image hash is already in the download history
    if grep -q "$IMAGE_HASH" "$DOWNLOAD_HISTORY_FILE"; then
        echo "Skipping an already downloaded wallpaper: $IMAGE_URL"
        return 0
    fi

    # Save the image to the wallpaper directory with the unique filename
    curl -Lf "$IMAGE_URL" > "$WALLPAPER_DIR/$UNIQUE_FILENAME"

    # Append the image hash to the download history file
    echo "$IMAGE_HASH" >> "$DOWNLOAD_HISTORY_FILE"

    # Increment the downloaded wallpaper counter
    ((DOWNLOADED_WALLPAPERS++))
}

# Function to show a countdown timer
show_countdown() {
    for ((i = SLEEP_DURATION; i >= 0; i--)); do
        printf "\rDownloading wallpaper %d of %d... Time left: %02d:%02d " "$DOWNLOADED_WALLPAPERS" "$MAX_WALLPAPERS" $((i / 60)) $((i % 60))
        sleep 1
    done
    echo ""
}

###  ENTRY POINT #######
########################

# Clear the screen before showing the banner
clear 

# Banner 
banner=$(cat << "EOF"
░█░█░█▀█░█░░░█░░░█▀█░█▀█░█▀█░█▀▀░█▀▄░░░█▀▄░█▀█░█░█░█▀█░█░░░█▀█░█▀█░█▀▄░█▀▀░█▀▄
░█▄█░█▀█░█░░░█░░░█▀▀░█▀█░█▀▀░█▀▀░█▀▄░░░█░█░█░█░█▄█░█░█░█░░░█░█░█▀█░█░█░█▀▀░█▀▄
░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀░░░▀▀▀░▀░▀░░░▀▀░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀
EOF
)

echo -e "${OKBLUE}$banner${ENDC}"
echo -e "${OKGREEN}Rev 3.5 by ${FAIL}Nitestryker${ENDC}"

# Wait for two seconds
sleep 2

# Clear the screen again 
clear

## GET USERS INPUT ###
######################

# Ask the user to choose the download mode (random or keyword)
exec 3>&1;
DOWNLOAD_MODE="$(dialog --backtitle "$backtitle" --inputbox "Choose the download mode (random/keyword):" 15 30 2>&1 1>&3)"
[[ "$DOWNLOAD_MODE" ]] || exit

if [ "$DOWNLOAD_MODE" == "keyword" ]; then
    exec 3>&1;
    KEYWORD="$(dialog --backtitle "$backtitle" --inputbox "Enter a keyword for wallpapers:" 15 30 2>&1 1>&3)"
    [[ "$KEYWORD" ]] || exit
elif [ "$DOWNLOAD_MODE" != "random" ]; then
    echo "Invalid download mode: $DOWNLOAD_MODE"
    exit 1  # Exit the script with an error code
fi

exec 3>&1;
MAX_WALLPAPERS="$(dialog --backtitle "$backtitle" --inputbox "Enter the maximum number of wallpapers to download (default: 100)" 15 30 2>&1 1>&3)"
[[ "$MAX_WALLPAPERS" ]] || exit

# Ask the user to input the sleep duration in seconds
exec 3>&1;
SLEEP_DURATION="$(dialog --backtitle "$backtitle" --inputbox "Enter the sleep duration in seconds between downloading wallpapers (default: 300)" 15 30 2>&1 1>&3)"
[[ "$SLEEP_DURATION" ]] || exit

# If the user didn't enter any value, set the default value to 300 seconds (5 minutes)
SLEEP_DURATION=${SLEEP_DURATION:-300}

# Sleep for one second
sleep 1

# Clear the screen 
clear

# Create the directory if it doesn't exist
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir "$WALLPAPER_DIR"
fi

# Create the download history file if it doesn't exist
touch "$DOWNLOAD_HISTORY_FILE"

# Set the initial value of the downloaded wallpaper counter to 0
DOWNLOADED_WALLPAPERS=0

#### Main loop #####
####################

while [ "$DOWNLOADED_WALLPAPERS" -lt "$MAX_WALLPAPERS" ]; do
    # Download the wallpaper based on the chosen mode (random or keyword)
    download_wallpaper

    # Show a notice and countdown before sleeping
    echo "Downloading wallpaper $DOWNLOADED_WALLPAPERS of $MAX_WALLPAPERS..."
    show_countdown
done

# Calculate the total download time
TOTAL_DOWNLOAD_TIME=$((MAX_WALLPAPERS * SLEEP_DURATION))

# Calculate the total data consumed in bytes
TOTAL_DATA_CONSUMED=$(du -c -b "$WALLPAPER_DIR" | grep "total$" | awk '{print $1}')

# Calculate the average download speed in bytes per second
if [ "$TOTAL_DOWNLOAD_TIME" -eq 0 ]; then
    AVERAGE_DOWNLOAD_SPEED=0
else
    AVERAGE_DOWNLOAD_SPEED=$(echo "scale=2; $TOTAL_DATA_CONSUMED / $TOTAL_DOWNLOAD_TIME" | bc)
fi

# Convert download statistics to appropriate units (bytes to MB or GB, seconds to minutes)
if (( $(echo "$TOTAL_DATA_CONSUMED > 1073741824" | bc -l) )); then
    TOTAL_DATA_CONSUMED=$(echo "scale=2; $TOTAL_DATA_CONSUMED / 1073741824" | bc)
    DATA_UNIT="GB"
elif (( $(echo "$TOTAL_DATA_CONSUMED > 1048576" | bc -l) )); then
    TOTAL_DATA_CONSUMED=$(echo "scale=2; $TOTAL_DATA_CONSUMED / 1048576" | bc)
    DATA_UNIT="MB"
else
    TOTAL_DATA_CONSUMED=$(echo "scale=2; $TOTAL_DATA_CONSUMED / 1024" | bc)
    DATA_UNIT="KB"
fi

if (( $(echo "$AVERAGE_DOWNLOAD_SPEED > 1048576" | bc -l) )); then
    AVERAGE_DOWNLOAD_SPEED=$(echo "scale=2; $AVERAGE_DOWNLOAD_SPEED / 1048576" | bc)
    SPEED_UNIT="MB/s"
elif (( $(echo "$AVERAGE_DOWNLOAD_SPEED > 1024" | bc -l) )); then
    AVERAGE_DOWNLOAD_SPEED=$(echo "scale=2; $AVERAGE_DOWNLOAD_SPEED / 1024" | bc)
    SPEED_UNIT="KB/s"
else
    SPEED_UNIT="B/s"
fi

# Clear the screen
clear

# Display download statistics
echo "Download Statistics:"
echo "Number of Wallpapers Downloaded: $DOWNLOADED_WALLPAPERS"
echo "Total Data Consumed: $TOTAL_DATA_CONSUMED $DATA_UNIT"
echo "Average Download Speed: $AVERAGE_DOWNLOAD_SPEED $SPEED_UNIT"

# Exit the script once the maximum number of wallpapers is downloaded
echo "Maximum number of wallpapers ($MAX_WALLPAPERS) downloaded. Exiting..."
