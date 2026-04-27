#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$REPO_URL" ]; then
  echo "Error: REPO_URL is not set."
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

# Automatically strip .git suffix from REPO_URL if present
REPO_URL=${REPO_URL%.git}

# Set default Dagger version if not provided
DAGGER_VERSION=${DAGGER_VERSION:-"latest"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted"}

# Append Dagger version to labels
FULL_LABELS="${RUNNER_LABELS},dagger:${DAGGER_VERSION}"

echo "Configuring runner for ${REPO_URL} with labels: ${FULL_LABELS}"

# Navigate to runner directory
cd /home/runner

# Register the runner
./config.sh --url "${REPO_URL}" \
            --token "${GITHUB_TOKEN}" \
            --labels "${FULL_LABELS}" \
            --unattended \
            --replace

# Define cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${GITHUB_TOKEN}"
}

# Trap signals for graceful shutdown
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

# Start the runner
./run.sh
