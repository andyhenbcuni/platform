#!/usr/bin/env bash
set -euo pipefail

# Source the Python environment setup script
source "cd-scripts/python_env_setup.sh"

# Function to display a banner message
display_banner() {
    echo "
  _   _   _   _     _   _   _   _   _   _   
 / \ / \ / \ / \   / \ / \ / \ / \ / \ / \
( T | E | S | T ) ( M | O | D | U | L | E )
 \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ 
"
}

process_module() {

    (

        # Check Python version and set environment
        check_and_set_python_env

        # Find test files while excluding .venv directories
        if [[ -n $(find . -path "./.venv" -prune -o -path "*/.venv" -prune -o -name '*_test*.py' -o -name 'test_*.py' -print) ]]; then
            poetry install

            # Run tests and capture coverage
            coverage_result=$(poetry run pytest --cov=.)

            # Extract the total coverage percentage
            total_coverage=$(awk '/TOTAL/ {print $NF}' <<< "$coverage_result" | tr -d '%')

            # Check coverage percentage
            if [[ "$total_coverage" -gt 0 ]]; then
                echo "Total Test Coverage is greater than 0%"
                return 0
            else
                echo "Total Test Coverage is not greater than 0%"
                return 1
            fi
        else
            echo "No tests found in module."
            return 0
        fi
    )

    exit_code=$?
    # Check if the shell scripts executed successfully
    if [[ $exit_code -eq 0 ]]; then
        echo "****************************** MODULE TEST PASSED **********************************"
    else
        echo "Error: Test failed for module "
    fi
}

# Main function to encapsulate the script logic
main() {
    process_module
}

# Execute the main function
main
