#!/usr/bin/env bash
# fetching a single pull request from GitHub

# Check if we are inside a Git repository
if [ ! -d ".git" ]; then
  echo "Error: Not inside a Git repository."
  exit 1
fi

# Check for the correct number of arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <pull_request_number> [branch_name]"
  exit 1
fi

PR=$1
BRANCH=$2

# Validate pull request number
if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: Pull request number must be a numeric value."
  exit 1
fi

# Default branch name if not provided
if [ -z "$BRANCH" ]; then
  BRANCH="pr-$PR"
fi

# Fetch the pull request
git fetch upstream pull/$PR/head:$BRANCH
if [ $? -ne 0 ]; then
  echo "Failed to fetch PR #$PR"
  exit 1
fi

# Checkout the branch
git checkout $BRANCH
if [ $? -ne 0 ]; then
  echo "Failed to checkout branch $BRANCH"
  exit 1
fi

echo "Checked out PR #$PR to branch $BRANCH"

