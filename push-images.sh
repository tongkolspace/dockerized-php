#!/bin/bash

# Function for countdown timer
countdown() {
    secs=$1
    while [ $secs -gt 0 ]; do
        echo -ne "Continuing in $secs seconds... Press Ctrl+C to cancel\r"
        sleep 1
        : $((secs--))
    done
    echo -e "\nProceeding..."
}

# Get current git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get last commit hash
COMMIT=$(git rev-parse --short HEAD)

# Check if --force flag is used
if [[ "$1" == "--force" ]]; then
    echo "Force flag detected. Proceeding without confirmation."
    echo "Git branch: $BRANCH"
    echo "Git commit: $COMMIT"
    countdown 5
else
    # Ask for confirmation
    echo "Do you want to push to registry container with these parameters?"
    echo "Git branch: $BRANCH"
    echo "Git commit: $COMMIT"
    read -p "Enter y or Y to continue: " CONFIRM

    if [[ ! $CONFIRM =~ ^[Yy]$ ]]
    then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Set version from last commit hash
VERSION=$COMMIT

# Rest of the script remains the same
# ...

echo "Images pushed successfully with version $VERSION and latest tags."