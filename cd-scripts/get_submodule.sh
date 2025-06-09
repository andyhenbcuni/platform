#!/usr/bin/env bash
set -xeuo pipefail

echo "****************************** GET SUBMODULE **********************************"

# Get the list of submodules with changes
sub_modules=$(git diff --name-only HEAD~1 HEAD | xargs -I {} dirname {} | cut -d '/' -f 1 | tr -d '.' | sed '/^$/d' | uniq)

# Print the submodules with changes
echo "Submodules with changes:"
echo "$sub_modules"
