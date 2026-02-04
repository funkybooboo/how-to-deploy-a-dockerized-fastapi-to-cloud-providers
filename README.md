# Deploy Dockerized FastAPI to Azure Container Apps

A complete tutorial for deploying a containerized FastAPI application to Microsoft Azure using Container Apps.

> **📚 General Documentation**: For application architecture, Docker guides, and local development, see the [docs/](./docs/) directory with 5 comprehensive guides covering FastAPI, Docker, development workflow, and API reference.

## What You'll Learn

- Set up a local development environment with Dev Containers
- Build a FastAPI application
- Deploy to Azure Container Apps
- Set up CI/CD with GitHub Actions

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/download)
- A Microsoft Azure account
- Azure CLI (can be installed in dev container)

## Tutorial Steps

Follow these guides in order:

1. **[Part 1: Create a Dev Container](./part_1.md)** - Set up local development environment
2. **[Part 2: Build a FastAPI Application](./part_2.md)** - Create FastAPI endpoints
3. **[Part 3: Deploy to Azure Container Apps](./part_3.md)** - Deploy to Azure
4. **[Part 4: Set Up CI/CD](./part_4.md)** - Configure GitHub Actions

## Quick Start

```bash
git clone <repo-url>
cd <repo-name>
git checkout azure
code .
# Reopen in Dev Container
```

## Architecture

- **Application:** FastAPI Python web framework
- **Container:** Docker with Python 3.12
- **Registry:** Azure Container Registry (ACR)
- **Hosting:** Azure Container Apps
- **CI/CD:** GitHub Actions

## Other Cloud Providers

See the [main branch README](../../tree/main) for an overview of all supported cloud providers.

## Credits

This project is based on the tutorial by Thaddeus Thomas:
- **Video Tutorial**: [How to Deploy a Dockerized FastAPI to Google Cloud Run](https://www.youtube.com/watch?v=DQwAX5pS4E8)
- **Original Repository**: [thaddavis/how-to-deploy-a-dockerized-fastapi-to-google-cloud-run](https://github.com/thaddavis/how-to-deploy-a-dockerized-fastapi-to-google-cloud-run/tree/main)

## License

GPL-3.0
