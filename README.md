# Multi-Architecture Docker Build with Native GitHub Runners

## How to build a Multi-Architecture Docker Image in Github Actions using multiple runners without QEMU

<center><img alt="Logo SREDevOps.org" src="https://www.sredevops.org/content/images/2024/11/sredevopsorg.svg" /></center>

Created by [SREDevOps.org](https://www,sredevops.org) | [@sredevopsorg](https://github.com/sredevopsorg) | [@ngeorger](https://github.com/ngeorger)

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/11363/badge)](https://www.bestpractices.dev/projects/11363)

By following these steps and reviewing the workflow file, you can customize and use this multi-architecture build process in your own projects. Happy building!

This repository demonstrates how to build multi-architecture Docker images (for example, **linux/amd64** and **linux/arm64**) using native GitHub runners instead of QEMU emulation. By leveraging separate native runners for each architecture, you get faster builds and higher fidelity (no emulation quirks) while still producing a single multi-arch image that you can push to GitHub Container Registry (GHCR).

> **Note:** This workflow requires access to both an AMD64 runner (using `ubuntu-latest`) and an ARM64 runner (for example, `ubuntu-24.04-arm`). Make sure your GitHub organization or repository has access to these runners.


## Overview

The workflow is divided into two main jobs:

1. **Build Job:**  
   - Uses a matrix strategy to build images for each platform separately.
   - Sets up a Docker context and configures Buildx to build images natively.
   - Logs into GHCR and builds & pushes the image by digest.
   - Exports the digest as an artifact for later use.

2. **Merge Job:**  
   - Downloads the digests from the build job.
   - Generates Docker image metadata (tags, labels, and annotations).
   - Uses Buildx to create a multi-architecture manifest list from the individual images.
   - Pushes the merged manifest (which tells Docker which image to pull based on the host architecture).

This two-step process creates a “fat” image that automatically delivers the correct binary for the user’s architecture.


## Features

- **Native Builds:** Uses GitHub’s native runners for each platform (no QEMU).
- **Multi-Arch Manifest:** Automatically merges per-architecture images into one multi-arch image.
- **Build Caching:** Implements caching to speed up subsequent builds.
- **OCI Metadata:** Adds labels and annotations for better image provenance.
- **Concurrency Control:** Uses GitHub Actions concurrency to cancel outdated builds.


## Getting Started

### Prerequisites

- A GitHub repository with this workflow set up.
- Access to GitHub-hosted runners for both **linux/amd64** and **linux/arm64**.
- A GitHub token (automatically provided as `GITHUB_TOKEN`) with permission to push to GHCR.
- A valid Dockerfile in the repository root (or modify the workflow’s context as needed).

### Setup

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/sredevopsorg/multi-arch-docker-github-workflow.git
   cd multi-arch-docker-github-workflow
   ```

2. **Review and Customize:**

   - **Dockerfile:**  
     The provided Dockerfile is a simple example. Customize it as needed for your application or replace it with your own.

   - **Workflow File:**  
     The GitHub Actions workflow is defined in `.github/workflows/multi-build.yaml`. You can adjust parameters (e.g., caching options, labels, annotations) if needed.

3. **Configure Secrets (if applicable):**

   - By default, the workflow uses the built-in `GITHUB_TOKEN` for authentication to GHCR. If you need to change registry credentials or add additional secrets, set them in your repository’s **Settings > Secrets and Variables**.


## How It Works (Step by Step)

### Build Job (Per-Architecture Build)

1. **Prepare Environment:**  
   The first step in the build job sets an environment variable (`PLATFORM_PAIR`) by replacing any `/` characters in the platform name with `-`. This ensures artifact names are valid.

2. **Checkout Code:**  
   The repository is checked out using [actions/checkout](https://github.com/actions/checkout).

3. **Generate Docker Metadata:**  
   The [docker/metadata-action](https://github.com/docker/metadata-action) creates metadata (tags, labels, annotations) based on repository information.

4. **Setup Docker Context and Buildx:**  
   - A new Docker context (named `builders`) is created.
   - The [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action) is configured to use that context and the specific platform from the matrix (either `linux/amd64` or `linux/arm64`).

5. **Login to GHCR:**  
   The workflow logs in to GitHub Container Registry using the `GITHUB_TOKEN`.

6. **Build and Push:**  
   Using [docker/build-push-action](https://github.com/docker/build-push-action), the image is built with the specified platform, labels, and caching options. The image is pushed by digest and the resulting digest is exported.

7. **Artifact Upload:**  
   The digest file is uploaded as an artifact (named with the platform pair) for use in the next job.

### Merge Job (Manifest Creation)

1. **Download Digests:**  
   The merge job downloads all the digest artifacts from the build job.

2. **Re-generate Docker Metadata:**  
   Metadata is generated again to ensure consistency with the built images.

3. **Setup Buildx and Login:**  
   The job sets up Buildx (this time without a custom context) and logs in to GHCR.

4. **Create Multi-Arch Manifest:**  
   The workflow runs `docker buildx imagetools create` to merge the images (using the digest files) into a single multi-architecture manifest list. Annotations such as description, creation timestamp, and source URL are added.

5. **Manifest Inspection:**  
   Finally, the merged image is inspected to verify that it contains the proper platform-specific entries.


## Triggering the Workflow

- **Automatic Trigger:**  
  Pushing changes to the `Dockerfile` or the workflow file (`.github/workflows/multi-build.yaml`) on the `main` branch will automatically trigger the workflow.

- **Manual Trigger:**  
  You can also trigger the workflow manually using the `workflow_dispatch` event.


## How to Use the Built Image

Once the workflow completes, your multi-architecture image is available in GHCR. For example, if your repository is `ghcr.io/your-org/your-repo`, you can pull the image as follows:

```bash
docker pull ghcr.io/your-org/your-repo:latest
```

Docker will automatically select the correct image based on your host’s CPU architecture.


## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [Issues](https://github.com/sredevopsorg/multi-arch-docker-github-workflow/issues) or submit a pull request.


## License

This project is licensed under the [MIT License](LICENSE).

