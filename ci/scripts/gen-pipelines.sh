#!/usr/bin/env bash
set -xeuo pipefail

readonly CI_DIR="$(dirname "$0")/.."
readonly CD_FILE="$CI_DIR/../cd.yml"
readonly BRANCHES_FILE="$OUTPUT_DIR/branches.yml"
readonly PIPELINES_LIST_FILE="$OUTPUT_DIR/pipelines-list.yml"

# Add a key on root level called branches:, sort branches & grab only their names
yq -P '{"branches": [[{}] + . | sort_keys(.[].name) | reverse | .[].name ]}' "./${SDH_BRANCHES}/branches.json" > "$BRANCHES_FILE"

touch "$PIPELINES_LIST_FILE"

for pipeline in $(yq -o=tsv '.pipelines | keys' $CD_FILE); do

    echo "- $pipeline" >> "$PIPELINES_LIST_FILE"

    template=$CI_DIR/templates/pipeline.yml

    ytt -f $template \
        --data-values-file=$BRANCHES_FILE > "$OUTPUT_DIR/$pipeline.yml"
done
