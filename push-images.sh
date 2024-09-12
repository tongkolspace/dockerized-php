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

# Image name
IMAGE_NAME_1="wordpress-ubuntu"
# IMAGE_NAME_2="wordpress-alpine"

# Input current directory as GIT_LOCATION
GIT_LOCATION=$(pwd)

BRANCH=$(git -C "$GIT_LOCATION" rev-parse --abbrev-ref HEAD)
COMMIT=$(git -C "$GIT_LOCATION" rev-parse --short HEAD)
MESSAGE=$(git -C "$GIT_LOCATION" log -1 --pretty=%B)


echo "Git Status"
echo "branch: $BRANCH"
echo "commit: $COMMIT"
echo "message: $MESSAGE"
echo "images: $IMAGE_NAME_1 "


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
if docker build . -t $IMAGE_NAME_1 -f $SCRIPT_DIR/Dockerfile; then
    echo "Build successful. Tagging and pushing images..."
    docker tag $IMAGE_NAME_1 gitea.tonjoo.com/tonjoo/$IMAGE_NAME_1:$VERSION
    docker tag $IMAGE_NAME_1 gitea.tonjoo.com/tonjoo/$IMAGE_NAME_1:latest
    
    # Push images
    if docker push gitea.tonjoo.com/tonjoo/$IMAGE_NAME_1:$VERSION && \
       docker push gitea.tonjoo.com/tonjoo/$IMAGE_NAME_1:latest; then
        echo "Images successfully pushed to registry."
    else
        echo "Failed to push images to registry."
        exit 1
    fi
else
    echo "Build failed. Aborting push operation."
    exit 1
fi

# Build Alpine images
# docker build . -t $IMAGE_NAME_2 -f DockerfileAlpine
# docker tag $IMAGE_NAME_2 gitea.tonjoo.com/tonjoo/$IMAGE_NAME_2:$VERSION
# docker tag $IMAGE_NAME_2 gitea.tonjoo.com/tonjoo/$IMAGE_NAME_2:latest
# docker push gitea.tonjoo.com/tonjoo/$IMAGE_NAME_2:$VERSION
# docker push gitea.tonjoo.com/tonjoo/$IMAGE_NAME_2:latest

echo "Images pushed successfully with version $VERSION and latest tags."