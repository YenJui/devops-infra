# devops-infra

This repository contains the infrastructure configuration for GitHub Self-hosted Runners optimized for **Dagger CI**, designed to be deployed on **Coolify**.

## Project Structure

- `runners/base/`: Contains the Dockerfile and entrypoint script for the custom runner image.
- `coolify/`: Contains the `docker-compose.yaml` for deploying via Coolify.
- `examples/`: Contains an example GitHub Action workflow that utilizes the custom runner.

## Key Features

- **Dagger CLI Integrated**: Dagger is pre-installed in the runner image.
- **Dynamic Labeling**: The runner automatically registers itself with a label indicating the Dagger version (e.g., `dagger:0.12.0`).
- **Graceful Cleanup**: Uses `trap` to ensure the runner is removed from GitHub when the container stops.
- **Non-root Execution**: The runner process executes as the `runner` user for security.
- **Docker-in-Docker Support**: Mounts the Docker socket to allow Dagger and other Docker operations.
- **Caching**: Persistent volume for Dagger cache (`/home/runner/.cache/dagger`).

## Environment Variables

The following environment variables are required for the runner:

| Variable | Description |
|----------|-------------|
| `GITHUB_TOKEN` | GitHub Personal Access Token with runner registration permissions. |
| `REPO_URL` | The URL of the repository or organization to register the runner with. |
| `RUNNER_LABELS` | Additional labels for the runner (default: `self-hosted`). |
| `DAGGER_VERSION`| The version of Dagger to label the runner with (default: `0.12.0`). |

## Deployment on Coolify

1. Create a new "Docker Compose" project in Coolify.
2. Use the content from `coolify/docker-compose.yaml`.
3. Set the environment variables in the Coolify dashboard.
4. Deploy.

## CI Usage

In your GitHub Action workflows, use:

```yaml
jobs:
  ci:
    runs-on: [self-hosted, "dagger:0.12.0"]
    steps:
      - run: dagger run go run ci/main.go
```
