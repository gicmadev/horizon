#!/bin/bash
set -ex

export REPO=gicmadev/horizon
export COMMIT=$(git rev-parse --short=8 HEAD)
export TAG=latest

docker build -f Dockerfile -t $REPO:$COMMIT .
docker tag $REPO:$COMMIT $REPO:$TAG
docker push $REPO

exec ./deploy.sh
