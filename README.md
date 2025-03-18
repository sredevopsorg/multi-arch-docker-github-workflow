# Multi-Architecture Docker Build with Native GitHub Runners

This repository demonstrates how to build multi-architecture Docker images using native GitHub runners for each platform (AMD64 and ARM64).

## Overview

The workflow builds Docker images for multiple CPU architectures:
- linux/amd64 (x86_64)
- linux/arm64 (aarch64)

Using native runners for each architecture ensures optimal build performance and compatibility.

## Features

- Uses GitHub's native runners (`ubuntu-latest` for AMD64 and `ubuntu-24.04-arm` for ARM64)
- Builds and pushes to GitHub Container Registry (GHCR)
- Implements build caching using GitHub Actions cache
- Creates and pushes multi-architecture manifest lists
- Includes OCI annotations for better image metadata
- Supports concurrent builds with cancellation of outdated runs

## Workflow steps explained

1. **Trigger Conditions**
   - Workflow runs on push to `main` branch or manual trigger
   - Uses concurrency to cancel outdated runs

2. **Build Job (`build`)**
   - Runs matrix strategy for two platforms:
     - linux/amd64 (on ubuntu-latest)
     - linux/arm64 (on ubuntu-24.04-arm)

   Steps:
   1. Prepare platform-specific environment
   2. Checkout code
   3. Setup Docker metadata for image tagging
   4. Configure Docker Buildx context
   5. Setup Docker Buildx with platform-specific settings
   6. Login to GitHub Container Registry
   7. Build and push platform-specific image with digest
   8. Export and upload digest as artifact

3. **Merge Job (`merge`)**
   - Runs after build job completes
   - Steps:
     1. Download all platform digests
     2. Setup Docker metadata
     3. Configure Docker Buildx
     4. Login to GHCR
     5. Create multi-arch manifest list with:
        - Repository description
        - Creation timestamp
        - Repository URL
        - Source URL
     6. Push final manifest
     7. Inspect created image

Key Features:

- Uses native runners for optimal performance
- Implements GitHub Actions cache for faster builds
- Creates OCI-compliant images with proper annotations
- Pushes to GitHub Container Registry using repository permissions
- Creates a unified multi-architecture manifest

The workflow produces a single multi-arch image that can run on both AMD64 and ARM64 platforms, automatically selecting the correct architecture at runtime.

## Workflow Configuration

The workflow is triggered on:
- Push to `main` branch
- Manual trigger (workflow_dispatch)

### Build Process

1. **Platform-specific builds**: Separate jobs run for each architecture
   - AMD64 build on `ubuntu-latest`
   - ARM64 build on `ubuntu-24.04-arm`

2. **Manifest Merge**: Combines platform-specific images into a multi-arch manifest

### Prerequisites

- GitHub repository with appropriate permissions
- Access to GitHub Container Registry (GHCR)
- No additional secrets required (uses `GITHUB_TOKEN`)

## Usage

### Automated Builds

Push to the `main` branch to trigger the workflow:

```bash
git push origin main
```

### Manual Builds

1. Go to the Actions tab in your repository
2. Select "Build multi arch Docker Image with separate Github Runners"
3. Click "Run workflow"

## Repository Structure

```
├── .github
│   └── workflows
│       └── multi-build.yaml    # GitHub Actions workflow file
├── Dockerfile                  # Simple example Dockerfile
└── README.md                  # This file
```

## Dockerfile

The example Dockerfile uses Alpine Linux and prints system information:

```dockerfile
FROM alpine:latest
RUN echo "Hello, World!" \
    && echo "This is a simple Dockerfile example." \
    && echo "$(uname -a)"
```

## Image Tags and Registry

Images are pushed to GitHub Container Registry with the following format:

- Registry: `ghcr.io`
- Image name: `ghcr.io/{owner}/{repository}`
- Tags: Generated based on Git context using `docker/metadata-action`

## License

This project is open-source and available under the MIT License.
