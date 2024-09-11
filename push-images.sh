#!/bin/bash
# Get current git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get last commit hash
COMMIT=$(git rev-parse --short HEAD)

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

# Set version from last commit hash
VERSION=$COMMIT

# Build images
docker build . -t wordpress-ubuntu -f Dockerfile
docker build . -t wordpress-alpine -f DockerfileAlpine

# Tag images with version and latest
docker tag wordpress-ubuntu gitea.tonjoo.com/tonjoo/wordpress-ubuntu:$VERSION
docker tag wordpress-ubuntu gitea.tonjoo.com/tonjoo/wordpress-ubuntu:latest
# docker tag wordpress-alpine gitea.tonjoo.com/tonjoo/wordpress-alpine:$VERSION
# docker tag wordpress-alpine gitea.tonjoo.com/tonjoo/wordpress-alpine:latest

# Push images with both version and latest tags
docker push gitea.tonjoo.com/tonjoo/wordpress-ubuntu:$VERSION
docker push gitea.tonjoo.com/tonjoo/wordpress-ubuntu:latest
# docker push gitea.tonjoo.com/tonjoo/wordpress-alpine:$VERSION
# docker push gitea.tonjoo.com/tonjoo/wordpress-alpine:latest

echo "Images pushed successfully with version $VERSION and latest tags."