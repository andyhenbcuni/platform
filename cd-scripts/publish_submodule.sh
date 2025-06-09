#!/usr/bin/env bash
set -euo pipefail

echo "**************************** Publish to Test PyPI Repository ***************************************"

# Step 1: Build the project using Poetry
echo "Building the project..."
poetry build || {
    echo "Build failed! Aborting publish."
    exit 1
}

# Step 2: Configure AR repo
readonly AR_REPO="https://us-python.pkg.dev/res-nbcupea-mgmt-003/mgds-public-pypi"
echo "Configure AR repo..."
poetry config repositories.ar $AR_REPO

echo "Auth with token from gcloud auth print-access-token..."
poetry config http-basic.ar oauth2accesstoken $(gcloud auth print-access-token)

# Step 3: Publish the package to the AR repository
echo "Publishing the package to the AR repo: $AR_REPO"
poetry publish --repository ar --skip-existing

# Check if the publishing was successful
if [ $? -eq 0 ]; then
    echo "Package published successfully to the PyPI repository."
else
    echo "Error: Failed to publish package to the PyPI repository."
fi
