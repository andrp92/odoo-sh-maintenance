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

for i in $(git submodule foreach --quiet 'echo $path')
do
  echo "Adding $i to root repo"
  git add "$i"
done

git checkout -b $BRANCH-update-submodules
git commit -m "[REF] *: updated $BRANCH to latest head of submodules"

if [ $DEPLOY == "prod" ]; then
  git checkout $BRANCH
  git merge --ff $BRANCH-update-submodules
  git push origin $BRANCH
  echo "Updated $(pwd) to latest head of submodules"
  exit 0;
fi

if [ $DEPLOY == "staging" ]; then
  # Merged local changes to staging branch
  git checkout $BRANCH-staging
  git merge --ff $BRANCH-update-submodules
  git push origin $BRANCH-staging
  echo "Updated $(pwd) to latest head of submodules"

  # Leave update branch available for merging into production later
  git checkout $BRANCH-update-submodules
  git push --set-upstream origin $BRANCH-update-submodules
  exit 0;
fi



