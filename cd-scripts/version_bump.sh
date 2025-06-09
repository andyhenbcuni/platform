#!/usr/bin/env bash
set -xuo pipefail

echo "**************************** VERSION BUMP **************************************"

# Get the latest commit message, trimming whitespace
latest_commit=$(git log -1 --pretty=%B | tr -d '\n\r')
echo "Latest Commit: $latest_commit"

# Enable nocasematch to perform case-insensitive matching
shopt -s nocasematch

readonly MODULE="$1"

# Get the current branch name
echo "Current branch: $PEA_CI_DEPLOY_BRANCH_FULL"

# If the branch name contains "release", skip the script
if [[ "$PEA_CI_DEPLOY_BRANCH_FULL" == *release* ]]; then
    echo "On a release branch. Skipping version bump and leaving the version unchanged."
    shopt -u nocasematch
    exit 0
fi

# Get the latest Git tag matching the format
latest_tag=$(git tag | grep -E "^${MODULE}-[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n1 || true)

if [[ -z "$latest_tag" ]]; then
    echo "No valid tags found. Assuming first release."
    exit 0
else
    echo "Latest Git tag: $latest_tag"
    # Extract the version part (e.g., from "module-1.0.0" -> "1.0.0")
    latest_tag=$(echo "$latest_tag" | sed "s/^${MODULE}-//")
fi

# Get the current version from Poetry
current_tag=$(poetry version | awk '{print $2}')
echo "Current version from Poetry: $current_tag"

# Function to compare semantic versions
compare_versions() {
    IFS='.' read -r -a current <<< "$1"
    IFS='.' read -r -a latest <<< "$2"

    for ((i=0; i<${#current[@]}; i++)); do
        if ((current[i] > latest[i])); then
            return 1 # current_tag > latest_tag
        elif ((current[i] < latest[i])); then
            return 2 # current_tag < latest_tag
        fi
    done
    return 0 # current_tag == latest_tag
}

# Compare versions
compare_versions "$current_tag" "$latest_tag"
comparison_result=$?

if [ $comparison_result -eq 1 ]; then
    echo "Current tag ($current_tag) is greater than latest tag ($latest_tag). Skipping version bump."
    shopt -u nocasematch
    exit 0
elif [ $comparison_result -eq 0 ]; then
    echo "Current tag ($current_tag) is equal to latest tag ($latest_tag). Proceeding with version bump."
elif [ $comparison_result -eq 2 ]; then
    echo "Current tag ($current_tag) is less than latest tag ($latest_tag). Updating version to latest tag."
    poetry version "$latest_tag"
fi

# Perform version bump based on commit keywords
if [[ $latest_commit =~ major ]]; then
    echo "Major version Release"
    poetry version major
elif [[ $latest_commit =~ minor ]]; then
    echo "Minor version Release"
    poetry version minor
elif [[ $latest_commit =~ (patch|bug) ]]; then
    echo "Patch version Release"
    poetry version patch
fi

# Disable nocasematch to revert to the previous behavior
shopt -u nocasematch

echo "**************************** UPDATING MAIN BRANCH ************************************"

echo "Current branch: $CURRENT_BRANCH"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "Current branch is not 'main'; no update will be performed."
    exit 0
fi

# Get the last commit hash (short form)
COMMIT_HASH=$(git rev-parse --short HEAD)

BRANCH_NAME="main-update-$COMMIT_HASH"
git checkout -b $BRANCH_NAME
git add pyproject.toml
git commit -am "Version bump commit"
git push -u origin $BRANCH_NAME
apt update
apt install gh
echo "$GIT_TOKEN" | gh auth login --with-token
gh pr create --base main --head $BRANCH_NAME --title "Update version for $MODULE" --body "Update version for $MODULE from commit $COMMIT_HASH"

echo "Created and pushed branch: $BRANCH_NAME and Pull request to main branch"
