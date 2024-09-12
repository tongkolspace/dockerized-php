#!/bin/bash

current_dir=$(pwd)
docker_dir=$(dirname "$current_dir")

# copy env
bash push-images.sh --force
bash wrapper.sh dev-local dev-container dev-proxy down --remove-orphans
bash wrapper.sh dev-local dev-container dev-proxy up -d