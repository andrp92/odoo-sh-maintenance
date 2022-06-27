#!/bin/bash

APP_PATH=$1
shift

if [ -z $APP_PATH ]; then
  echo "Missing 1st argument: should be path to folder of a git repo";
  exit 1;
fi

BRANCH=$1
shift

if [ -z $BRANCH ]; then
  echo "Missing 2nd argument (branch name)";
  exit 1;
fi

DEPLOY=$1
shift

if [ -z $DEPLOY ]; then
  echo "Missing 3rd argument (deploy prod or staging)";
  exit 1;
fi

echo "Working in: $APP_PATH / $(pwd)"
cd $APP_PATH

# Set main git config
git config user.name github-actions
git config user.email github-actions@github.com

# UPDATE PROCESS
git submodule foreach "(git reset --hard origin/$BRANCH)" # reset to latest head of submodule
git submodule sync
git submodule init
git submodule update
git submodule foreach "(git checkout $BRANCH && git pull --ff origin $BRANCH) || true"

for i in $(git submodule foreach --quiet 'echo $path')
do
  echo "Adding $i to root repo"
  git add "$i"
done

git checkout -b $BRANCH-update-submodules
git commit -m "[REF] *: updated $BRANCH to latest head of submodules"
git push -d origin $BRANCH-update-submodules
git push --set-upstream origin $BRANCH-update-submodules
git checkout $BRANCH

if [ $DEPLOY == "prod" ]; then
  git checkout $BRANCH
  git merge --ff $BRANCH-update-submodules
  git push origin $BRANCH
  echo "Updated $(pwd) to latest head of submodules"
  exit 0;
fi

if [ $DEPLOY == "staging" ]; then
  # Merged local changes to staging branch
  git checkout $BRANCH-staging || (echo "No staging branch found, creating new branch" && git checkout -b $BRANCH-staging)
  git merge --ff $BRANCH-update-submodules || exit 1
  git push origin $BRANCH-staging
  echo "Updated $(pwd) to latest head of submodules"
  exit 0;
fi
