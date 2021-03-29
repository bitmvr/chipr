#!/usr/bin/env bash

# set -x

if [ $# -eq 0 ]; then
  echo "ERROR: Please provide the MAIN branch for this project in order to exclude it."
  exit 1
fi

readonly MAIN_BRANCH="$1"
readonly SCRIPT_NAME="$(basename "$0")"

notBranch(){
  branchName="$1"
  grep --invert-match ".*/${branchName}$"
}

getMergedBranches(){
  git branch --remote --merged
}

getShortnameForRemote(){
  local_path="$(git rev-parse --show-toplevel)"
  local_path="${local_path##*/}"
  echo "$local_path"
}

removeRemoteShortname(){
  branchName="$1"
  branchName="${branchName#*/}"
  echo "$branchName"
}

checkoutBranch(){
  branch="$1"
  if ! git checkout "${branch}" > /dev/null 2>&1; then
    return 1
  fi
}

pullLatest(){
  branch="$1"
  if ! git pull origin "${branch}" > /dev/null 2>&1; then
    return 1
  fi
}

deleteRemoteBranch(){
  branches="$1"
  if ! git push --delete origin "$branches" > /dev/null 2>&1; then
    return 1
  fi
}

isGitRepository(){
  if [ ! -d .git ]; then
    return 1 
  fi
}

toLower(){
 string="$1"
 echo "$string" | tr '[:upper:]' '[:lower:]'
}

getAvailableBranches(){
  mainBranch="$MAIN_BRANCH"
  branches="$(getMergedBranches | notBranch "${mainBranch}")"

  for branch in $branches; do
    branch="$(removeRemoteShortname "${branch}")"
    echo "$branch"
  done
}

listAvailableBranches(){
  for branch in $(getAvailableBranches); do
    echo " - $branch"
  done
}

isYes(){
  string="$1"
  string="$(toLower "${string}")"
  if [ "$string" == "y" ] || [ "$string" == "yes" ]; then
    return 0
  else
    return 1
  fi
}

isNo(){
  string="$1"
  string="$(toLower "${string}")"
  if [ "$string" == "n" ] || [ "$string" == "no" ]; then
    return 0
  else
    return 1
  fi
}

confirmDelete(){
  echo "Are you sure you want to delete these branches?"
  read -r -p "Yes[Y] / No[N]: " response

  if isYes "$response"; then
    return 0
  elif isNo "$response"; then
    return 1
  else
    echo "ERROR: Invalid response. Exiting..."
    return 1
  fi
}

main(){
  mainBranch="$MAIN_BRANCH"
  scriptName="${SCRIPT_NAME}"
  
  if ! isGitRepository; then
    echo "ERROR: ${scriptName} must be executed from the project's root directory."
    exit 1
  fi

  if ! checkoutBranch "$mainBranch"; then
    echo "ERROR: Could not checkout ${mainBranch}."
    exit 1
  fi

  if ! pullLatest "$mainBranch"; then
    echo "ERROR: Could not pull the latest version of ${mainBranch} with the remote."
    exit 1
  fi

  echo ""
  echo "Branches To Be Deleted"
  echo "---------------------------------------------"

  if ! listAvailableBranches; then
    echo "ERROR: Could not get all available branches."
    exit 1
  fi

  echo ""
  if ! confirmDelete; then
    exit 1
  fi

  for branch in $(getAvailableBranches); do
    if ! deleteRemoteBranch "${branch}"; then
      echo "ERROR: Could not delete the branch: ${branch}"
    else
      echo "Deleted: ${branch}"
    fi
  done 
}

main
