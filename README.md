# How to build a Multi-Architecture Docker Image in Github Actions using multiple runners without QEMU

By [SREDevOps.org](https://sredevops.org) @sredevopsorg @ngeorger

This repository demonstrates how to build multi-architecture Docker images using native GitHub runners for each platform (amd64 and arm64). This approach avoids QEMU emulation, providing better performance, faster builds and parallel builds using the new [Github Linux arm64 Hosted Runners](https://github.blog/changelog/2025-01-16-linux-arm64-hosted-runners-now-available-for-free-in-public-repositories-public-preview/) alongside the Github Linux amd64 Hosted Runners.

## Overview

The workflow builds Docker images for multiple CPU architectures:

- `linux/amd64` (x86_64)
- `linux/arm64` (aarch64)

It leverages native GitHub runners for each architecture to ensure optimal build performance and compatibility. The workflow builds and pushes images to GitHub Container Registry (GHCR).

## Features

- **Native Runners**: Uses `ubuntu-latest` for AMD64 and `ubuntu-24.04-arm` for ARM64.
- **GitHub Container Registry (GHCR)**: Builds and pushes images to GHCR.
- **Build Caching**: Implements build caching using GitHub Actions cache.
- **Multi-Arch Manifests**: Creates and pushes multi-architecture manifest lists.
- **OCI Annotations**: Includes OCI annotations for better image metadata.
- **Concurrency Management**: Supports concurrent builds with cancellation of outdated runs.

## Workflow Overview

The workflow is triggered on:

- Push to the `main` branch (when Dockerfile or workflow file changes)
- Manual trigger (workflow_dispatch)

### Permissions

The workflow requires the following permissions:

- `contents: read`: To read the repository's contents.
- Job-specific permissions are defined for each job to allow writing to GHCR, creating attestations, and more.

### Concurrency

The workflow uses a concurrency group to ensure that only one job runs at a time for a given branch and workflow. If a new job is triggered, the previous one is canceled.

## Usage

### Automated Builds

Push changes to the `Dockerfile` or `.github/workflows/multi-build.yaml` on the `main` branch to trigger the workflow automatically:

## Workflow Steps

The workflow consists of two main jobs: `build` and `merge`.

### 1. Build Job

The `build` job builds the Docker image for each platform specified in the matrix (`linux/amd64` and `linux/arm64`).

#### Steps

1. **Prepare environment for current platform**: Sets up the environment for the current platform being built. It replaces the `/` character in the platform name with `-` and sets it as an environment variable (`PLATFORM_PAIR`).
2. **Checkout**: Checks out the code from the repository.
3. **Docker meta default**: Generates metadata for the Docker image using the `docker/metadata-action`.
4. **Set up Docker Context for Buildx**: Sets up a Docker context for Buildx.
5. **Set up Docker Buildx**: Sets up Docker Buildx with the specified context and platforms.
6. **Login to GitHub Container Registry**: Logs in to GHCR using the `docker/login-action`.
7. **Build and push by digest**: Builds and pushes the Docker image using Buildx. It uses the `docker/build-push-action` to build the image with the specified context and platforms. The image is built with labels and annotations. Caching is enabled using GitHub Actions cache.
8. **Export digest**: Exports the digest of the built image to a file.
9. **Upload digest**: Uploads the digest file to GitHub Actions artifact storage.

### 2. Merge Job

The `merge` job merges the Docker manifests for the different platforms built in the `build` job.

#### Steps

1. **Download digests**: Downloads the digest files uploaded in the `build` job.
2. **Docker meta**: Generates metadata for the Docker image.
3. **Set up Docker Buildx**: Sets up Docker Buildx.
4. **Login to GitHub Container Registry**: Logs in to GHCR.
5. **Get execution timestamp with RFC3339 format**: Gets the current execution timestamp in RFC3339 format.
6. **Create manifest list and pushs**: Creates a manifest list for the Docker images built for different platforms. It uses the `docker buildx imagetools create` command to create the manifest list. The manifest list is annotated with metadata.
7. **Create manifest list and push without annotations**: Creates a manifest list without annotations if the previous step fails.
8. **Inspect image**: Inspects the created manifest list to verify its contents.

## Auto generated image name

- `GHCR_IMAGE`: The name of the Docker image to be built and pushed to GHCR (e.g., `ghcr.io/your-org-or-user/your-repo-name`).

```yaml
# This workflow builds a multi-arch Docker image using GitHub Actions and separated Github Runners with native support for ARM64 and AMD64 architectures, without using QEMU emulation.
# It uses Docker Buildx to build and push the image to GitHub Container Registry (GHCR).
name: Build multi arch Docker Image with separate Github Runners

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - 'Dockerfile'
      - '.github/workflows/multi-build.yaml'
env:
  # The name of the Docker image to be built and pushed to GHCR
  # The image name is derived from the GitHub repository name and the GitHub Container Registry (GHCR) URL.
  # The image name will be in the format: ghcr.io/<owner>/<repo>
  GHCR_IMAGE: ghcr.io/${{ github.repository }}

permissions:
  # Global permissions for the workflow, which can be overridden at the job level
  contents: read

concurrency:
  # This concurrency group ensures that only one job in the group runs at a time.
  # If a new job is triggered, the previous one will be canceled.
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # The build job builds the Docker image for each platform specified in the matrix.
  build:
    strategy:
      fail-fast: false
      matrix:
        platform:
          - linux/amd64
          - linux/arm64
      # The matrix includes two platforms: linux/amd64 and linux/arm64.
      # The build job will run for each platform in the matrix.

    permissions:
      # Permissions for the build job, which can be overridden at the step level
      # The permissions are set to allow the job to write to the GitHub Container Registry (GHCR) and read from the repository.
      attestations: write
      actions: read
      checks: write
      contents: write
      deployments: none
      id-token: write
      issues: read
      discussions: read
      packages: write
      pages: none
      pull-requests: read
      repository-projects: read
      security-events: read
      statuses: read

    runs-on: ${{ matrix.platform == 'linux/amd64' && 'ubuntu-latest' || matrix.platform == 'linux/arm64' && 'ubuntu-24.04-arm' }}
    # The job runs on different runners based on the platform.
    # For linux/amd64, it runs on the latest Ubuntu runner.
    # For linux/arm64, it runs on an Ubuntu 24.04 ARM runner.
    # The runner is selected based on the platform specified in the matrix.

    name: Build Docker image for ${{ matrix.platform }}

    steps:
      -
        name: Prepare environment for current platform 
        # This step sets up the environment for the current platform being built.
        # It replaces the '/' character in the platform name with '-' and sets it as an environment variable.
        # This is useful for naming artifacts and other resources that cannot contain '/'.
        # The environment variable PLATFORMS_PAIR will be used later in the workflow.
        id: prepare
        run: |
          platform=${{ matrix.platform }}
          echo "PLATFORM_PAIR=${platform//\//-}" >> $GITHUB_ENV

      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        # This step checks out the code from the repository.
        # It uses the actions/checkout action to clone the repository into the runner's workspace.

      - name: Docker meta default
        # This step generates metadata for the Docker image.
        # It uses the docker/metadata-action to create metadata based on the repository information.
        # The metadata includes information such as the image name, tags, and labels.
        # The metadata will be used later in the workflow to build and push the Docker image.
        id: meta
        uses: docker/metadata-action@902fa8ec7d6ecbf8d84d538b9b233a880e428804 # v5.7.0
        with:
          images: ${{ env.GHCR_IMAGE }}

      - name: Set up Docker Context for Buildx
        # This step sets up a Docker context for Buildx.
        # It creates a new context named "builders" that will be used for building the Docker image.
        # The context allows Buildx to use the Docker daemon for building images.
        id: buildx-context
        run: |
          docker context create builders

      - name: Set up Docker Buildx
        # This step sets up Docker Buildx, which is a Docker CLI plugin for extended build capabilities with BuildKit.
        # It uses the docker/setup-buildx-action to configure Buildx with the specified context and platforms.
        # The platforms are specified in the matrix and will be used for building the Docker image.
        uses: docker/setup-buildx-action@b5ca514318bd6ebac0fb2aedd5d36ec1b5c232a2 # v3.10.0
        with:
          endpoint: builders
          platforms: ${{ matrix.platform }}

      - name: Login to GitHub Container Registry
        # This step logs in to the GitHub Container Registry (GHCR) using the docker/login-action.
        # It uses the GitHub actor's username and the GITHUB_TOKEN secret for authentication.
        uses: docker/login-action@74a5d142397b4f367a81961eba4e8cd7edddf772 # v3.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}


      - name: Build and push by digest
        # This step builds and pushes the Docker image using Buildx.
        # It uses the docker/build-push-action to build the image with the specified context and platforms.
        # The image is built with the labels and annotations generated in the previous steps.
        # The outputs are configured to push the image by digest, which allows for better caching and versioning.
        # The cache-from and cache-to options are used to enable caching for the build process.
        # The cache is stored in GitHub Actions cache and is scoped to the repository, branch, and platform.
        id: build
        uses: docker/build-push-action@471d1dc4e07e5cdedd4c2171150001c434f0b7a4 # v6.15.0
        env:
          DOCKER_BUILDKIT: 1
        with:
          context: .
          platforms: ${{ matrix.platform }}
          labels: ${{ steps.meta.outputs.labels }}
          annotations: ${{ steps.meta.outputs.annotations }}
          outputs: type=image,name=${{ env.GHCR_IMAGE }},push-by-digest=true,name-canonical=true,push=true,oci-mediatypes=true
          cache-from: type=gha,scope=${{ github.repository }}-${{ github.ref_name }}-${{ matrix.platform }}
          cache-to: type=gha,scope=${{ github.repository }}-${{ github.ref_name }}-${{ matrix.platform }}


      - name: Export digest
        # This step exports the digest of the built image to a file.
        # It creates a directory in /tmp/digests and saves the digest of the image to a file.
        # The digest is obtained from the output of the build step.
        # The digest is used to uniquely identify the built image and can be used for further processing or verification.
        run: |
          mkdir -p /tmp/digests
          digest="${{ steps.build.outputs.digest }}"
          touch "/tmp/digests/${digest#sha256:}"

      - name: Upload digest
        # This step uploads the digest file to the GitHub Actions artifact storage.
        # It uses the actions/upload-artifact action to upload the file created in the previous step.
        # The artifact is named digests-${{ env.PLATFORM_PAIR }}, where PLATFORM_PAIR is the platform name with '/' replaced by '-'.
        # The artifact is retained for 1 day, and if no files are found, it will throw an error.      
        uses: actions/upload-artifact@4cec3d8aa04e39d1a68397de0c4cd6fb9dce8ec1 # v4.6.1
        with:
          name: digests-${{ env.PLATFORM_PAIR }}
          path: /tmp/digests/*
          if-no-files-found: error
          retention-days: 1


  merge:
    # This job merges the Docker manifests for the different platforms built in the previous job.
    name: Merge Docker manifests
    runs-on: ubuntu-latest
    permissions:
      attestations: write
      actions: read
      checks: read
      contents: read
      deployments: none
      id-token: write
      issues: read
      discussions: read
      packages: write
      pages: none
      pull-requests: read
      repository-projects: read
      security-events: read
      statuses: read

    needs:
      - build
      # This job depends on the build job to complete before it starts.
      # It ensures that the Docker images for all platforms are built before merging the manifests.
    steps:
      - name: Download digests
        # This step downloads the digest files uploaded in the build job.
        # It uses the actions/download-artifact action to download the artifacts with the pattern digests-*.
        # The downloaded files are merged into the /tmp/digests directory.
        uses: actions/download-artifact@cc203385981b70ca67e1cc392babf9cc229d5806 # v4.1.9
        with:
          path: /tmp/digests
          pattern: digests-*
          merge-multiple: true


      - name: Docker meta
        # This step generates metadata for the Docker image.
        # It uses the docker/metadata-action to create metadata based on the repository information.
        # The metadata includes information such as the image name, tags, and labels.
        id: meta
        uses: docker/metadata-action@902fa8ec7d6ecbf8d84d538b9b233a880e428804 # v5.7.0
        with:
          images: ${{ env.GHCR_IMAGE }}
          annotations: |
            type=org.opencontainers.image.description,value=${{ github.event.repository.description || 'No description provided' }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@b5ca514318bd6ebac0fb2aedd5d36ec1b5c232a2 # v3.10.0
        # This step sets up Docker Buildx, which is a Docker CLI plugin for extended build capabilities with BuildKit.
        with:
          driver-opts: |
            network=host

      - name: Login to GitHub Container Registry
        uses: docker/login-action@74a5d142397b4f367a81961eba4e8cd7edddf772 # v3.4.0
        # This step logs in to the GitHub Container Registry (GHCR) using the docker/login-action.
        # It uses the GitHub actor's username and the GITHUB_TOKEN secret for authentication.
        # The login is necessary to push the merged manifest list to GHCR.
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Get execution timestamp with RFC3339 format
        # This step gets the current execution timestamp in RFC3339 format.
        # It uses the date command to get the current UTC time and formats it as a string.
        # The timestamp is used for annotating the Docker manifest list.
        id: timestamp
        run: |
          echo "timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> $GITHUB_OUTPUT

      - name: Create manifest list and pushs
        # This step creates a manifest list for the Docker images built for different platforms.
        # It uses the docker buildx imagetools create command to create the manifest list.
        # The manifest list is annotated with metadata such as description, creation timestamp, and source URL.
        # The annotations are obtained from the metadata generated in the previous steps.
        # The manifest list is pushed to the GitHub Container Registry (GHCR) with the specified tags.
        working-directory: /tmp/digests
        id: manifest-annotate
        continue-on-error: true
        run: |
              docker buildx imagetools create \
                $(jq -cr '.tags | map("-t " + .) | join(" ")' <<< "$DOCKER_METADATA_OUTPUT_JSON") \
                --annotation='index:org.opencontainers.image.description=${{ github.event.repository.description }}' \
                --annotation='index:org.opencontainers.image.created=${{ steps.timestamp.outputs.timestamp }}' \
                --annotation='index:org.opencontainers.image.url=${{ github.event.repository.url }}' \
                --annotation='index:org.opencontainers.image.source=${{ github.event.repository.url }}' \
                $(printf '${{ env.GHCR_IMAGE }}@sha256:%s ' *)

      - name: Create manifest list and push without annotations
        # This step creates a manifest list for the Docker images built for different platforms.
        # It uses the docker buildx imagetools create command to create the manifest list.
        # The manifest list is created without annotations if the previous step fails.
        # The manifest list is pushed to the GitHub Container Registry (GHCR) with the specified tags.
        if: steps.manifest-annotate.outcome == 'failure'
        working-directory: /tmp/digests
        run: |
              docker buildx imagetools create  $(jq -cr '.tags | map("-t " + .) | join(" ")' <<< "$DOCKER_METADATA_OUTPUT_JSON") \
                $(printf '${{ env.GHCR_IMAGE }}@sha256:%s ' *)

      - name: Inspect image
        # This step inspects the created manifest list to verify its contents.
        # It uses the docker buildx imagetools inspect command to display information about the manifest list.
        # The inspection output will show the platforms and tags associated with the manifest list.
        id: inspect
        run: |
          docker buildx imagetools inspect '${{ env.GHCR_IMAGE }}:${{ steps.meta.outputs.version }}'
```

## Repository Structure

```
├── .github
│   └── workflows
│       └── multi-build.yaml    # GitHub Actions workflow file
├── Dockerfile                  # Simple example Dockerfile
└── README.md                  # This file
```

## License

This project is open-source and available under the MIT License.

