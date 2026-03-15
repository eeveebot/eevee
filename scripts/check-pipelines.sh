#!/bin/bash

# Script to check latest pipeline status for each project
# Requires gh CLI tool to be installed and authenticated

# Configuration
SCRIPT_PATH="${BASH_SOURCE[0]}"
# Resolve symlink
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ $SCRIPT_PATH == /* ]] || SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

# Change to the project root directory (assuming the script is in docs/scripts/)
cd "$SCRIPT_DIR/../.." || { echo "Failed to change to project root directory"; exit 1; }

# Print table header
printf "%-20s %-10s %-15s %-20s %-15s %-50s\n" "PROJECT" "COMMIT" "PIPELINE TAG" "LATEST TAG" "PIPELINE STATUS" "PIPELINE URL"
printf "%-20s %-10s %-15s %-20s %-15s %-50s\n" "-------" "------" "------------" "----------" "--------------" "-----------"

# Counter for mismatches
MISMATCH_COUNT=0

# Find all directories with .git subdirectories (git repositories)
for dir in */; do
    if [ -d "$dir/.git" ]; then
        PROJECT_NAME="${dir%/}"
        cd "$dir"
        
        # Get the latest commit hash
        COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
        if [ $? -ne 0 ]; then
            COMMIT_HASH="N/A"
        fi
        
        # Initialize variables
        PIPELINE_TAG="None"
        LATEST_TAG="None"
        RUN_STATUS="Unable to fetch"
        RUN_URL="N/A"
        
        # Get pipeline status and commit SHA using gh CLI
        RUN_DATA=$(gh run list --limit 1 --json databaseId,status,conclusion,headSha,url 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$RUN_DATA" ]; then
            # Parse JSON data
            RUN_STATUS=$(echo "$RUN_DATA" | jq -r '.[0].conclusion // .[0].status' 2>/dev/null)
            RUN_SHA=$(echo "$RUN_DATA" | jq -r '.[0].headSha' 2>/dev/null)
            RUN_URL=$(echo "$RUN_DATA" | jq -r '.[0].url' 2>/dev/null)
            
            # Check if we got a valid SHA
            if [ -n "$RUN_SHA" ] && [ "$RUN_SHA" != "null" ] && [ "$RUN_SHA" != "" ]; then
                # Get the tag associated with the pipeline run commit
                PIPELINE_TAG=$(git describe --tags "$RUN_SHA" 2>/dev/null)
                if [ $? -ne 0 ] || [ -z "$PIPELINE_TAG" ]; then
                    PIPELINE_TAG="None"
                else
                    # Check if this tag belongs to the main branch
                    TAG_COMMIT=$(git rev-list -n 1 "$PIPELINE_TAG" 2>/dev/null)
                    if [ -n "$TAG_COMMIT" ]; then
                        # Check if this commit is in the main branch history
                        if ! git merge-base --is-ancestor "$TAG_COMMIT" "main" 2>/dev/null; then
                            # Skip this tag as it doesn't belong to main branch
                            PIPELINE_TAG="None"
                            RUN_STATUS="Skipped (not on main)"
                        fi
                    fi
                fi
            fi
        fi
        
        # Get the latest tag that belongs to the main branch
        MAIN_HEAD=$(git rev-parse main 2>/dev/null)
        if [ $? -eq 0 ]; then
            LATEST_ON_MAIN=$(git describe --tags $(git rev-list --tags --max-count=1 --first-parent main 2>/dev/null) 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$LATEST_ON_MAIN" ]; then
                LATEST_TAG="$LATEST_ON_MAIN"
            else
                LATEST_TAG="None"
            fi
        else
            LATEST_TAG="None"
        fi
        
        # Mark mismatches between pipeline tag and latest tag
        if [ "$PIPELINE_TAG" != "$LATEST_TAG" ] && [ "$PIPELINE_TAG" != "None" ] && [ "$LATEST_TAG" != "None" ]; then
            PIPELINE_TAG="${PIPELINE_TAG} (!)"  # Mark mismatch
            LATEST_TAG="${LATEST_TAG} (!)"  # Mark mismatch
            MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
        fi
        
        # Print table row
        printf "%-20s %-10s %-15s %-20s %-15s %-50s\n" "$PROJECT_NAME" "$COMMIT_HASH" "$PIPELINE_TAG" "$LATEST_TAG" "$RUN_STATUS" "$RUN_URL"
        
        cd ..
    fi
done

# Print summary
echo ""
if [ $MISMATCH_COUNT -gt 0 ]; then
    echo "WARNING: $MISMATCH_COUNT project(s) have tag mismatches between pipeline run and latest tags."
else
    echo "All projects have pipeline runs consistent with the latest tags."
fi
