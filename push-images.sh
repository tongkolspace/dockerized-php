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

# Get last commit message
MESSAGE=$(git log -1 --pretty=%B)

echo "Git Status"
echo "branch: $BRANCH"
echo "commit: $COMMIT"
echo "message: $MESSAGE"


# Check if --force flag is used
if [[ "$1" == "--force" ]]; then
    echo "Force flag detected. Proceeding without confirmation."

    countdown 5
else
    # Ask for confirmation
    echo "Do you want to push to registry container with these parameters?"
    read -p "Enter y or Y to continue: " CONFIRM

    if [[ ! $CONFIRM =~ ^[Yy]$ ]]
    then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Set version from last commit hash
VERSION=$COMMIT

# Build images
docker build . -t wordpress-ubuntu -f Dockerfile
docker tag wordpress-ubuntu gitea.tonjoo.com/tonjoo/wordpress-ubuntu:$VERSION
docker tag wordpress-ubuntu gitea.tonjoo.com/tonjoo/wordpress-ubuntu:latest
docker push gitea.tonjoo.com/tonjoo/wordpress-ubuntu:$VERSION
docker push gitea.tonjoo.com/tonjoo/wordpress-ubuntu:latest

# Build Alpine images
docker build . -t wordpress-alpine -f DockerfileAlpine
docker tag wordpress-alpine gitea.tonjoo.com/tonjoo/wordpress-alpine:$VERSION
docker tag wordpress-alpine gitea.tonjoo.com/tonjoo/wordpress-alpine:latest
docker push gitea.tonjoo.com/tonjoo/wordpress-alpine:$VERSION
docker push gitea.tonjoo.com/tonjoo/wordpress-alpine:latest

echo "Images pushed successfully with version $VERSION and latest tags."