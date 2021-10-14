#!/usr/bin/env bash
# This script is meant to build and compile every protocolbuffer for each
# service declared in this repository (as defined by sub-directories).
# It compiles using docker containers based on Namely's protoc image
# seen here: https://github.com/namely/docker-protoc

set -e

REPOPATH=${REPOPATH-/$HOME/protolangs}
CURRENT_BRANCH=${CIRCLE_BRANCH-"branch-not-available"}

# Helper for adding a directory to the stack and echoing the result
function enterDir {
  echo "Entering $1"
  pushd $1 > /dev/null
}

# Helper for popping a directory off the stack and echoing the result
function leaveDir {
  echo "Leaving `pwd`"
  popd > /dev/null
}

# Finds all directories in the repository and iterates through them calling the
# compile process for each one
function buildAll {
  echo "Buidling service's protocol buffers"
  mkdir -p $REPOPATH
  
  reponame="protorepo-jagw-go"

  rm -rf $REPOPATH/$reponame

  echo "Cloning repo: git@github.com:jalapeno-api-gateway/$reponame.git"

  # Clone the repository down and set the branch to the automated one
  git clone git@github.com:jalapeno-api-gateway/$reponame.git $REPOPATH/$reponame
  setupBranch $REPOPATH/$reponame
  
  mkdir -p jagw
  protoc --proto_path=. --go_out=./jagw --go_opt=paths=source_relative --go-grpc_out=./jagw --go-grpc_opt=paths=source_relative **/*.proto
  
  cp -R jagw/* $REPOPATH/$reponame/
  rm -rf jagw/
  commitAndPush $REPOPATH/$reponame
}

function setupBranch {
  enterDir $1

  echo "Creating branch"

  if ! git show-branch $CURRENT_BRANCH; then
    git branch $CURRENT_BRANCH
  fi

  git checkout $CURRENT_BRANCH

  if git ls-remote --heads --exit-code origin $CURRENT_BRANCH; then
    echo "Branch exists on remote, pulling latest changes"
    git pull origin $CURRENT_BRANCH
  fi

  leaveDir
}

function commitAndPush {
  enterDir $1

  git add -N .

  if ! git diff --exit-code > /dev/null; then
    git add .
    git commit -m "Auto Creation of Proto"
    git push origin HEAD
  else
    echo "No changes detected for $1"
  fi

  leaveDir
}

buildAll