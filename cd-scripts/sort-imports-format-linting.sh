#!/usr/bin/env bash
set -xeuo pipefail

readonly CURRENT_BRANCH="$(cat .git/resource/head_name)"

# step out to root level
cd ../
git clone --branch "${CURRENT_BRANCH}" --single-branch  https://${GIT_TOKEN}@github.com/NBCUDTC/mgds-pipelines-library-src.git
cd mgds-pipelines-library-src/

echo "Checking out mgds-pipelines-library-src repo with branch: ${CURRENT_BRANCH}, where the last commit is $(git rev-parse --short HEAD)"

# Source the Python environment setup script
source "cd-scripts/python_env_setup.sh"
# Check Python version and set environment
check_and_set_python_env

# Install project dependencies using Poetry
echo "Installing project dependencies..."
poetry install || {
    echo "poetry install failed"
    exit 1
}

# Run isort for import sorting
echo "Running isort..."
poetry run isort -v . || {
    echo "isort failed"
    exit 1
}

# Run black for code formatting
echo "Running black..."
poetry run black -v . || {
    echo "black failed"
    exit 1
}

# Check if there are any changes
if ! git diff --quiet; then

    # Configure git user
    git config --global user.email "concourse@nbcudtc.com"
    git config --global user.name "nbcudtc-concourse"

    readonly last_commit_msg="$(git log -1 --pretty=%B | tr -d '\n\r')"

    # Commit changes
    echo "Committing changes..."
    git commit -am "[AMENDED] ${last_commit_msg}" || {
        echo "Commit failed"
        exit 1
    }

    # Push changes
    echo "Pushing changes..."
    git push origin "${CURRENT_BRANCH}" || {
        echo "Push failed"
        exit 1
    }
fi

# Run flake8 for linting
# echo "Running flake8..."
# poetry run flake8 -v . || {
#     echo "flake8 failed"
#     exit 1
# }
