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

# Automatically strip .git suffix and trailing slashes
REPO_URL=$(echo "${REPO_URL}" | sed 's/\.git$//' | sed 's/\/$//')

# Fix Docker socket permissions if it exists
if [ -S /var/run/docker.sock ]; then
  echo "Fixing Docker socket permissions..."
  sudo chmod 666 /var/run/docker.sock
fi

# Extract Owner and Repo from URL (e.g., https://github.com/owner/repo)
OWNER_REPO=$(echo "${REPO_URL}" | sed 's/.*github.com\///')

echo "Detected Repo: ${OWNER_REPO}"

# 1. Get a Registration Token via API
echo "Fetching registration token from GitHub..."
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${OWNER_REPO}/actions/runners/registration-token" | jq -r '.token')

if [ "$REG_TOKEN" == "null" ] || [ -z "$REG_TOKEN" ]; then
  echo "Error: Failed to get registration token. Check your GITHUB_TOKEN permissions and REPO_URL."
  exit 1
fi

# Set default Dagger version if not provided
DAGGER_VERSION=${DAGGER_VERSION:-"latest"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted"}
RUNNER_NAME=${RUNNER_NAME:-$(hostname)}
FULL_LABELS="${RUNNER_LABELS},dagger:${DAGGER_VERSION}"

echo "Configuring runner ${RUNNER_NAME} for ${REPO_URL} with labels: ${FULL_LABELS}"

# Navigate to runner directory
cd /home/runner

# 2. Register the runner using the retrieved Registration Token
./config.sh --url "${REPO_URL}" \
            --token "${REG_TOKEN}" \
            --name "${RUNNER_NAME}" \
            --labels "${FULL_LABELS}" \
            --unattended \
            --replace

# Define cleanup function
cleanup() {
    set +e
    echo "Removing runner ${RUNNER_NAME}..."
    # Get a fresh removal token
    REMOVE_TOKEN=$(curl -s -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${OWNER_REPO}/actions/runners/remove-token" | jq -r '.token')
    
    if [ "$REMOVE_TOKEN" != "null" ] && [ -n "$REMOVE_TOKEN" ]; then
        ./config.sh remove --token "${REMOVE_TOKEN}"
    else
        echo "Failed to get removal token, cannot remove runner from GitHub."
    fi
}

# Trap signals for graceful shutdown
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

# Start the runner
./run.sh &
wait $!
