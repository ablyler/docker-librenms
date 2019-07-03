#!/usr/bin/env bash
set -e

PROJECT=librenms
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_TAG=docker_build
BUILD_WORKINGDIR=${BUILD_WORKINGDIR:-.}
DOCKERFILE=${DOCKERFILE:-Dockerfile}
VCS_REF=${TRAVIS_COMMIT::7}
RUNNING_TIMEOUT=120
RUNNING_LOG_CHECK="snmpd entered RUNNING state"

PUSH_LATEST=${PUSH_LATEST:-true}
DOCKER_USERNAME=${DOCKER_USERNAME:-librenms}
DOCKER_REPONAME=${DOCKER_REPONAME:-librenms}
DOCKER_LOGIN=${DOCKER_LOGIN:-librenmsbot}
QUAY_USERNAME=${QUAY_USERNAME:-librenms}
QUAY_REPONAME=${QUAY_REPONAME:-librenms}
QUAY_LOGIN=${QUAY_LOGIN:-librenms+travis}

ARCHITECTURES="arm amd64"

for arch in $ARCHITECTURES
do
# Build for all architectures and push manifest
  platforms="linux/$arch,$platforms"
done

platforms=${platforms::-1}

# Login into docker
docker login --username $DOCKER_USER --password $DOCKER_PASSWORD

# Check local or travis
BRANCH=${TRAVIS_BRANCH:-local}
if [[ ${TRAVIS_PULL_REQUEST} == "true" ]]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH}
fi
DOCKER_TAG=${BRANCH:-local}
if [[ "$BRANCH" == "master" ]]; then
  DOCKER_TAG=latest
elif [[ "$BRANCH" == "local" ]]; then
  BUILD_DATE=
  VERSION=local
fi

echo "PROJECT=${PROJECT}"
echo "VERSION=${VERSION}"
echo "BUILD_DATE=${BUILD_DATE}"
echo "BUILD_TAG=${BUILD_TAG}"
echo "BUILD_WORKINGDIR=${BUILD_WORKINGDIR}"
echo "DOCKERFILE=${DOCKERFILE}"
echo "VCS_REF=${VCS_REF}"
echo "PUSH_LATEST=${PUSH_LATEST}"
echo "DOCKER_LOGIN=${DOCKER_LOGIN}"
echo "DOCKER_USERNAME=${DOCKER_USERNAME}"
echo "DOCKER_REPONAME=${DOCKER_REPONAME}"
echo "QUAY_LOGIN=${QUAY_LOGIN}"
echo "QUAY_USERNAME=${QUAY_USERNAME}"
echo "QUAY_REPONAME=${QUAY_REPONAME}"
echo "TRAVIS_BRANCH=${TRAVIS_BRANCH}"
echo "TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST}"
echo "BRANCH=${BRANCH}"
echo "DOCKER_TAG=${DOCKER_TAG}"
echo

# Build
echo "### Build"
buildctl build --frontend dockerfile.v0 \
      --local dockerfile=. \
      --local context=. \
      --exporter type=image \
      --exporter-opt name=docker.io/${DOCKER_USER}/${DOCKER_REPONAME}:${DOCKER_TAG} \
      --exporter-opt push=true \
      --opt platform=$platforms \
      --opt filename=${DOCKERFILE} \
      --opt build-arg:BUILD_DATE=${BUILD_DATE} \
      --opt build-arg:VCS_REF=${VCS_REF} \
      --opt build-arg:VERSION=${VERSION}
echo

wait
