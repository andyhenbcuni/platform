#!/usr/bin/env bash

# Function to check and set the Python environment based on .python-version or pyproject.toml
check_and_set_python_env() {
    local pyproject_file="pyproject.toml"
    local python_version=""

    # If .python-version exists, try to use it
    if [[ -f .python-version ]]; then
        python_version=$(<.python-version)
        python_version=$(echo "$python_version" | xargs)
    fi

    # If no Python version in .python-version, fall back to pyproject.toml
    if [[ -z "$python_version" ]]; then
        # Extract Python version constraint from pyproject.toml
        python_version=$(grep -E '^python = "[^"]+"' "$pyproject_file" | sed -E 's/python = "(.*)"/\1/')
        python_version=$(echo "$python_version" | xargs)

        if [[ -z "$python_version" ]]; then
            echo "Error: Python version not specified in $pyproject_file or .python-version."
            return 1
        fi

        echo "Python version specified in pyproject.toml: $python_version"

        # If python_version starts with ">=3."
        if [[ "$python_version" == ">=3."* ]]; then
            minor_version="${python_version#>=3.}"
            minor_version="${minor_version%%[^0-9]*}"
            python_version="3.${minor_version}"
            echo "Detected Python version constraint '>=3.${minor_version}', setting Python version to $python_version"
        fi
    else
        echo "Using Python version from .python-version: $python_version"
    fi

    # Check if the required Python version is installed using pyenv
    if ! pyenv versions --bare | grep -E "^${python_version}(\.[0-9]+)?$" >/dev/null; then
        echo "Python version $python_version is not installed. Installing now..."
        pyenv install "$python_version"
    else
        echo "Python version $python_version is already installed."
    fi

    # Set the Python version using pyenv
    pyenv local "$python_version"
    echo "Python environment set to version $python_version using pyenv."

    # Install Poetry and set it to use the correct Python version
    pip install poetry
    poetry env use "$(pyenv which python)" || { echo "Error setting Poetry environment"; exit 1; }
    echo "Poetry environment set to Python version $python_version."
}
