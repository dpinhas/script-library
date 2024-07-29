#!/bin/bash

# Check if at least four arguments are provided (Gerrit URL, repository URL, branch name, and at least one change ID)
if [ $# -lt 4 ]; then
  echo "Usage: $0 <gerrit_url> <repository_url> <branch_name> <change_id1> [<change_id2> ...]"
  exit 1
fi

# Extract Gerrit URL, repository URL, and branch name from arguments
gerrit_url=$1
repository_url=$2
branch_name=$3
shift 3  # Remove the first three arguments, leaving only change IDs

# Function to extract ref from JSON
extract_ref() {
  local json=$1
  # Extract the ref from JSON using jq
  ref=$(echo "$json" | jq -r '.[0].current_revision')

  if [ -z "$ref" ]; then
    echo "Error: Unable to extract the ref from the JSON response or invalid JSON format."
    exit 1
  fi

  echo "$ref"
}

# Create or checkout to the specified branch
git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"

# Loop through the provided change IDs
for change_id in "$@"; do
  # Query Gerrit server for the change ID
  url="${gerrit_url}/changes/?q=${change_id}&o=CURRENT_REVISION"
  json_response=$(curl -s "$url")

  # Check if the JSON response is empty
  if [ -z "$json_response" ]; then
    echo "Error: Unable to fetch JSON response for change $change_id from Gerrit."
    continue
  fi

  # Extract the ref from the JSON response
  ref=$(extract_ref "$json_response")

  # Output the ref for the change ID
  echo "Ref for change $change_id: $ref"

  # Fetch the change and cherry-pick
  git fetch "$repository_url" "$ref" && git cherry-pick FETCH_HEAD
done

