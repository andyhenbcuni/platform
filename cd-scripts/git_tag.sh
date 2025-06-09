#!/usr/bin/env bash
set -xeuo pipefail

echo "**************************** GIT TAGGING ************************************"

# Get the current version from Poetry
version=$(poetry version)

# Print the version information
echo "Version: $version"

# Format the version for tagging (assuming version format like "x.y.z")
formatted_version=$(echo "$version" | awk '{print $1"-"$2}')

# Print the formatted version
echo "Formatted Version: $formatted_version"

# Check if the tag already exists
if git rev-parse "$formatted_version" >/dev/null 2>&1; then
    echo "Tag '$formatted_version' already exists. Skipping tagging."
else
    # Tag the commit with the formatted version
    git tag "$formatted_version"

    # Push the tag to the remote repository
    git push origin "$formatted_version"

    # Check if tagging was successful
    if [ $? -eq 0 ]; then
        echo "Tag '$formatted_version' created and pushed successfully."
    else
        echo "Error: Failed to tag and push '$formatted_version'."
    fi
fi
