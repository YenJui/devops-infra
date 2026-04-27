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
FULL_LABELS="${RUNNER_LABELS},dagger:${DAGGER_VERSION}"

echo "Configuring runner for ${REPO_URL} with labels: ${FULL_LABELS}"

# Navigate to runner directory
cd /home/runner

# 2. Register the runner using the retrieved Registration Token
./config.sh --url "${REPO_URL}" \
            --token "${REG_TOKEN}" \
            --labels "${FULL_LABELS}" \
            --unattended \
            --replace

# Define cleanup function (needs a fresh token for removal, but let's keep it simple)
cleanup() {
    echo "Removing runner..."
    # Get a fresh removal token
    REMOVE_TOKEN=$(curl -s -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${OWNER_REPO}/actions/runners/remove-token" | jq -r '.token')
    ./config.sh remove --token "${REMOVE_TOKEN}"
}

# Trap signals for graceful shutdown
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

# Start the runner
./run.sh
