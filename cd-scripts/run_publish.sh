#!/usr/bin/env bash
set -xeuo pipefail


# step out to root level
cd ../
git clone --branch "${PEA_CI_DEPLOY_BRANCH_FULL}" --single-branch  https://${GIT_TOKEN}@github.com/NBCUDTC/mgds-pipelines-library-src.git
cd mgds-pipelines-library-src/

echo "Checking out mgds-pipelines-library-src repo with branch: ${PEA_CI_DEPLOY_BRANCH_FULL}, where the last commit is $(git rev-parse --short HEAD)"

pip install keyring
# Keyring disable command (uncomment if needed)
keyring --disable

# Source the Python environment setup script
source "cd-scripts/python_env_setup.sh"

# Function to print a banner
print_banner() {
    echo "
  _   _   _   _   _   _   _     _   _   _   _   _   _
 / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ 
( P | U | B | L | I | S | H ) ( M | O | D | U | L | E )
 \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/
"
}

process_module() {

    (

        # Check Python version and set environment
        check_and_set_python_env

        # Check the branch name
        echo "Current branch: $PEA_CI_DEPLOY_BRANCH_FULL"

        # Get the latest commit message
        latest_commit=$(git log -1 --pretty=%B)

        # Get the current image name and version from Poetry
        library_name=$(poetry version | awk '{print $1}')
        current_tag=$(poetry version | awk '{print $2}')

        # Format the expected Git tag (e.g., "library_name-1.0.0")
        formatted_tag="${library_name}-${current_tag}"
        # Get the latest Git tag for this image
        latest_tag=$(git tag | grep -E "^${library_name}-[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n1 || true)

        if [[ -z "$latest_tag" ]]; then
            echo "No Git tags found. Assuming first release."
            latest_tag="${library_name}-1.0.0"
        fi
        echo "Latest Git tag: $latest_tag"

        # Extract the version part from the latest tag
        latest_version=$(echo "$latest_tag" | sed "s/^${library_name}-//")
        echo "Latest version: $latest_version"

        # Enable nocasematch to perform case-insensitive matching
        shopt -s nocasematch

        # Handle main branch logic
        if [[ "$PEA_CI_DEPLOY_BRANCH_FULL" == "main" ]]; then
            if [[ "$latest_version" == "1.0.0" && "$current_tag" == "1.0.0" ]]; then
                echo "First release of the image. Proceeding with release."
            elif [[ ! "$latest_commit" =~ (major|minor|bug|patch) ]]; then
                echo "On the main branch with no version bump keywords in the commit message. Skipping everything."
                return 0
            fi
        fi

        # Handle release branch logic
        if [[ "$PEA_CI_DEPLOY_BRANCH_FULL" == *release* ]]; then
            echo "On a release branch. Verifying current version matches Git tags."
            if git tag | grep -qw "${library_name}-${current_tag}"; then
                echo "Error: Current tag (${library_name}-${current_tag}) already exists in Git tags. Exiting to prevent duplication."
                exit 1
            fi
        fi

        bash cd-scripts/version_bump.sh "$library_name" &&
        bash cd-scripts/publish_submodule.sh "$library_name" &&
        bash cd-scripts/git_tag.sh
    )

    # Check if the shell scripts executed successfully
    if [[ $? -eq 0 ]]; then
        echo "****************************** MODULE PUBLISHED **********************************"
    else
        echo "Error: Failed to process package "
    fi
}

# Main function to encapsulate the script logic
main() {
    process_module
}

# Execute the main function
main
