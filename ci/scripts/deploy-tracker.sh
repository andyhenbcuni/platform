#!/usr/bin/env bash
PIPELINE_NAME=mgds-pipelines-library-tracker
TARGET_NAME=decision-sciences
CI_PATH=".."

fly login -t "$TARGET_NAME" --team-name ds-recs-peacock -c https://concourse-mgmt.nbcupea.mgmt.nbcuott.com/

ytt -f "$CI_PATH"/templates/tracker.yml > "$CI_PATH/${PIPELINE_NAME}.yml"

fly set-pipeline -t "$TARGET_NAME" -c "$CI_PATH/${PIPELINE_NAME}.yml" -p "$PIPELINE_NAME"

rm "$CI_PATH/${PIPELINE_NAME}.yml"
