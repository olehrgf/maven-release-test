#!/bin/bash

### Parameters
default_branch="master"
release_branch="release/latest"
#maven_args=""

#mvn build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}-${BUILD_NUMBER}"
mvn versions:set \
  -DprocessAllModules=true \
  -DremoveSnapshot=true \

mvn clean install

# Read the version
version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
#version_release=${version%-SNAPSHOT}

echo "[*] Commit new incremental version to $default_branch"
git checkout $default_branch
git merge --no-ff $release_branch
git commit -a -m "[release] Automatic incremental release v$version"
git tag -a "v$version" -m "[release] Automatic incremental release v$version"

echo "[*] Commit new incremental version to $release_branch"
git checkout -b $release_branch
git commit -m "[release] Automatic incremental release v$version"
git push --force origin $release_branch

#git checkout $default_branch
#mvn build-helper:parse-version versions:set \
#  -DnextSnapshot=true \
#  -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
#
#version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
#git commit -m "[release] Automatic incremental development iteration v$version"
#git push --force origin $default_branch
#
#git branch -D $release_branch






















#if [[ -n "$RELEASE_VERSION" ]]; then
#  version_release=$RELEASE_VERSION
#  maven_args="$maven_args -DreleaseVersion=$version_release"
#fi
#
#if [[ -n "$DEV_VERSION" ]]; then
#  maven_args="$maven_args -DdevelopmentVersion=$DEV_VERSION"
#fi
#
#
#function assert_snapshot_version() {
#  if [[ "$version" != *-SNAPSHOT* ]]; then
#    echo "fatal - Cannot release the project is not a SNAPSHOT version."
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#function assert_branch_version_exist() {
#  git show-ref --verify --quiet "refs/heads/release/v$version_release"
#  if [ $? -eq 0 ]; then
#    echo "fatal - A local branch already exist release/v$version_release."
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#
#  git ls-remote --exit-code . "origin/release/v$version_release" &>/dev/null
#  if [ $? -eq 0 ]; then
#    echo "fatal - A remote branch already exist release/v$version_release."
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#function assert_tag_version_exist() {
#  git show-ref --verify --quiet "refs/tags/v$version_release"
#  if [ $? -eq 0 ]; then
#    echo "fatal - A local tag already exist tags/v$version_release."
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#
#  git ls-remote --exit-code . "tags/v$version_release" &>/dev/null
#  if [ $? -eq 0 ]; then
#    echo "fatal - A remote tag already exist tags/v$version_release."
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#function maven_release() {
#  echo "[#] Perform maven release"
#  # perform a maven release, which will tag this branch and deploy artifacts to artifactory (http://apps.axon-id.com/artifactory/)
#  mvn --batch-mode release:prepare $maven_args
#  if [ $? -ne 0 ]; then
#    echo 'fatal: Cannot do mvn release:prepare'
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#
#  if [ $maven_skip_release != 'true' ]; then
#    mvn release:perform $maven_args
#    if [ $? -ne 0 ]; then
#      echo "fatal - Cannot do mvn release:perform"
#      echo "[###] Released v$version_release [FAILED]"
#      exit 1
#    fi
#  fi
#
#  mvn release:clean $maven_args
#  if [ $? -ne 0 ]; then
#    echo "fatal - Cannot do mvn release:clean"
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#function checkout_release_branch() {
#  echo "[#] Checkout branch '$release_branch'"
#  git checkout $release_branch
#  git pull origin $release_branch
#
#  if [ $? -ne 0 ]; then
#    echo "fatal - Cannot pull branch '$release_branch'"
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#function checkout_default_branch() {
#  echo "[#] MAJ branch '$default_branch'"
#  git checkout $default_branch
#  git pull origin $default_branch
#
#  if [ $? -ne 0 ]; then
#    echo "fatal - Cannot pull branch $default_branch"
#    echo "[###] Released v$version_release [FAILED]"
#    exit 1
#  fi
#}
#
#echo "-----------------------------------------------------------------------"
#echo " Release $version to $version_release "
#echo " (local branch : $default_branch) "
#echo "-----------------------------------------------------------------------"
#
#assert_snapshot_version
#assert_branch_version_exist
#assert_tag_version_exist
#
##checkout_release_branch
#checkout_default_branch
#
#echo "[#] create branch release/v$version "
### branch from default to a new release branch
#git checkout $default_branch
#git checkout -b release/v$version_release
#
#maven_release
#
#echo "[#] Merge release/v$version_release to $default_branch"
### merge the version changes back into develop so that folks are working against the new release ("0.0.3-SNAPSHOT", in this case)
#git checkout $default_branch
#git merge --no-ff release/v$version_release
#
### housekeeping -- rewind the release branch by one commit to fix its version at "0.0.2"
###	excuse the force push, it's because maven will have already pushed '0.0.3-SNAPSHOT'
###	to origin with this branch, and I don't want that version (or a diverging revert commit)
###	in the release or $release_branch branches.
#git checkout release/v$version_release
#git reset --hard HEAD~1
#git push --force origin release/v$version_release
##git push --force origin $release_branch
##git checkout $default_branch
#
##echo "[#] Merge release/v$version_release to $release_branch"
### finally, if & when the code gets deployed to production
##git checkout $release_branch
##git rebase release/v$version_release
##git merge --no-ff release/v$version_release
##git push --force origin $release_branch
#
#echo "[###] Released v$version_release [SUCCESS]"
