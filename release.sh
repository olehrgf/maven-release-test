#!/bin/bash

# How to perform a release with git & maven following the git flow conventions
# ----------------------------------------------------------------------------
# Finding the next version: you can see the next version by looking at the
#	version element in "pom.xml" and lopping off "-SNAPSHOT". To illustrate,
#	if the pom's version read "0.0.2-SNAPSHOT", the following instructions would
#	perform the release for version "0.0.2" and increment the development version
#	of each project to "0.0.3-SNAPSHOT".
#
#  If you need to specify the local branch to release (it needs to be created)
#  release.sh --branch <name_local_branch>
#  release.sh -b <name_local_branch>
#
#  Specify is a hotfix branch / it will merge on 'MASTER' and 'DEVELOP'
#  release.sh -hf <true/false>
#  release.sh --hotfix <true/false>
#
#  Specify maven arguments (during release/perform goal)
#  release.sh --maven_args <arguments>
#
#
#  [REQUIRED] need the libxml-xpath-perl / sudo apt-get install  libxml-xpath-perl
#
# Read the version
version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
version_release=${version%-SNAPSHOT}

### Parameters
default_branch='master'
release_branch='release'
maven_args=''
maven_skip_release='true'
#
#
#while [ $# -gt 1 ] ; do
#case $1 in
#-b) default_branch=$2 ; shift 2 ;;
#--branch) default_branch=$2 ; shift 2 ;;
#-hf) hotfix=$2 ; shift 2 ;;
#--hotfix) hotfix=$2 ; shift 2 ;;
#--maven_args) maven_args=$2 ; shift 2 ;;
#*) shift 1 ;;
#esac
#done
#
function assert_snapshot_version() {
  if [[ "$version" != *-SNAPSHOT* ]]; then
    echo "fatal - Cannot release the project is not a SNAPSHOT version."
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi
}

function assert_branch_version_exist() {
  git show-ref --verify --quiet "refs/heads/release/v$version_release"
  if [ $? -eq 0 ]; then
    echo "fatal - A local branch already exist release/v$version_release."
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi

  git ls-remote --exit-code . "origin/release/v$version_release" &>/dev/null
  if [ $? -eq 0 ]; then
    echo "fatal - A remote branch already exist release/v$version_release."
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi
}

function assert_tag_version_exist() {
  git show-ref --verify --quiet "refs/tags/v$version_release"
  if [ $? -eq 0 ]; then
    echo "fatal - A local tag already exist tags/v$version_release."
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi

  git ls-remote --exit-code . "tags/v$version_release" &>/dev/null
  if [ $? -eq 0 ]; then
    echo "fatal - A remote tag already exist tags/v$version_release."
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi
}

function maven_release() {
  echo "[#] Perform maven release"
  # perform a maven release, which will tag this branch and deploy artifacts to artifactory (http://apps.axon-id.com/artifactory/)
  mvn release:prepare $maven_args
  if [ $? -ne 0 ]; then
    echo 'fatal: Cannot do mvn release:prepare'
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi

  if [ $maven_skip_release != 'true' ]; then
    mvn release:perform $maven_args
    if [ $? -ne 0 ]; then
      echo "fatal - Cannot do mvn release:perform"
      echo "[###] Released v$version_release [FAILED]"
      exit 1
    fi
  fi

  mvn release:clean $maven_args
  if [ $? -ne 0 ]; then
    echo "fatal - Cannot do mvn release:clean"
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi
}

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

function checkout_default_branch() {
  echo "[#] MAJ branch '$default_branch'"
  git checkout $default_branch
  git pull origin $default_branch

  if [ $? -ne 0 ]; then
    echo "fatal - Cannot pull branch $default_branch"
    echo "[###] Released v$version_release [FAILED]"
    exit 1
  fi
}

echo "-----------------------------------------------------------------------"
echo " Release $version to $version_release "
echo " (local branch : $default_branch) "
echo "-----------------------------------------------------------------------"

assert_snapshot_version
assert_branch_version_exist
assert_tag_version_exist

#checkout_release_branch
checkout_default_branch

echo "[#] create branch release/v$version "
## branch from default to a new release branch
git checkout -b release/v$version_release
git checkout $default_branch

maven_release

echo "[#] Merge release/v$version_release to $default_branch"
## merge the version changes back into develop so that folks are working against the new release ("0.0.3-SNAPSHOT", in this case)
git checkout release/v$version_release
git merge --no-ff $default_branch

## housekeeping -- rewind the release branch by one commit to fix its version at "0.0.2"
##	excuse the force push, it's because maven will have already pushed '0.0.3-SNAPSHOT'
##	to origin with this branch, and I don't want that version (or a diverging revert commit)
##	in the release or $release_branch branches.
#git checkout release/v$version_release
git reset --hard HEAD~1
git push --force origin release/v$version_release
#git checkout $default_branch
#
#echo "[#] Merge release/v$version_release to $release_branch"
#
### finally, if & when the code gets deployed to production
#git checkout $release_branch
#git merge --no-ff release/v$version_release
#git push --all && git push --tags

#if $hotfix; then
#  echo "[!] hotfix activated, going to merge on branch 'develop'"
#  git checkout develop
#  git pull origin develop
#  git merge --no-ff release/v$version_release
#  git push origin HEAD
#fi

##delete branch release local and remote
#git branch -d release/v$version_release
#git push origin :release/v$version_release
#
echo "[###] Released v$version_release [SUCCESS]"
