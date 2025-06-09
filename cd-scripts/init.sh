#!/usr/bin/env bash
set -euo pipefail
## debug mode
set -x


if [[ -f "$SCRIPT_FILE" ]]; then
    echo "Start ${SCRIPT_FILE}"
    bash $SCRIPT_FILE
else
    echo "Script by path $SCRIPT_FILE doesn't exist."
    echo "Skipping $SCRIPT_FILE phase"
fi
