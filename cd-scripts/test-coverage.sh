#!/usr/bin/env bash
set -xeuo pipefail

# Run test coverage script
echo "Checking test coverage..."
bash cd-scripts/check_test_coverage.sh || {
    echo "Test coverage check failed"
    exit 1
}
