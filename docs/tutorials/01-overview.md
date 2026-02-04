# Tutorial 01: Overview - Deploy FastAPI to Azure Container Apps

## What You'll Build

In this tutorial series, you'll deploy a production-ready FastAPI application to **Azure Container Apps** - Microsoft's fully managed serverless container platform.

### The Complete System

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   GitHub    │─────▶│GitHub Actions│─────▶│ Azure Container │
│ Repository  │      │   (CI/CD)    │      │    Registry     │
└─────────────┘      └──────────────┘      └─────────────────┘
                                                     │
                                                     ▼
┌─────────────┐                            ┌─────────────────┐
│   Users     │◀───────────────────────────│ Container Apps  │
│             │   HTTPS (auto-cert)        │   (Service)     │
└─────────────┘                            └─────────────────┘
```

### Key Features

- **FastAPI Application** - Modern Python web framework with automatic API docs
- **Docker Containers** - Consistent deployments across environments
- **Azure Container Registry** - Private container image storage
- **Azure Container Apps** - Serverless container hosting with auto-scaling
- **GitHub Actions** - Automated testing and deployment
- **Automatic HTTPS** - Free SSL certificates
- **Zero-downtime Deployments** - Rolling updates
- **Auto-scaling** - Scales from 0 to handle any load

## Why Azure Container Apps?

### Serverless Simplicity

- **No server management** - Azure handles infrastructure
- **Pay per use** - Costs scale with actual usage
- **Auto-scaling** - From 0 to 300+ instances automatically
- **Free tier** - 180,000 vCPU-seconds and 360,000 GB-seconds per month

### Developer Friendly

- **Any container** - Bring any Docker image
- **Built-in features** - HTTPS, monitoring, logging included
- **Fast deployments** - Changes live in seconds
- **Easy rollbacks** - Revert to previous versions instantly

### Production Ready

- **High availability** - Multi-zone redundancy
- **Custom domains** - Use your own domain names
- **API-driven** - Automate everything with Azure CLI
- **Monitoring** - Application Insights integration

## What Makes This Tutorial Different?

### Comprehensive Learning

Unlike quick-start tutorials, you'll understand:
- **Why** each step is necessary
- **How** the components work together
- **What** happens behind the scenes
- **When** to use different approaches

### Hands-On Practice

- Complete working code examples
- Step-by-step instructions
- Troubleshooting guides
- Validation at each step

### Production Focus

Not just "hello world" - you'll learn:
- Security best practices
- Cost optimization
- Monitoring and debugging
- CI/CD automation

## Learning Path

### Phase 1: Foundation (Tutorials 01-04)

**Time**: 1-2 hours

1. **Overview** (you are here) - Understand what you're building
2. **Prerequisites** - Install required tools and create accounts
3. **Local Setup** - Get the application running locally
4. **Understanding FastAPI** - Learn the framework fundamentals

**Goal**: Solid foundation before deployment

### Phase 2: Manual Deployment (Tutorial 05)

**Time**: 1-2 hours

5. **Manual Deployment** - Deploy to Azure step-by-step

**What you'll do**:
- Create Azure resources (Container Registry, Container Apps)
- Build and push Docker images
- Deploy your application
- Test the live deployment

**Goal**: Understand the complete deployment process

### Phase 3: Automation (Tutorials 06-08)

**Time**: 1-2 hours

6. **CI/CD Setup** - Automate with GitHub Actions
7. **Monitoring** - Logs, metrics, and debugging
8. **Cleanup** - Remove resources to avoid charges

**Goal**: Professional workflow with automation

## What You'll Learn

### Core Skills

- **Azure CLI** - Command-line management of Azure resources
- **Azure Container Registry** - Store and manage container images
- **Azure Container Apps** - Deploy and scale containerized applications
- **Docker** - Build optimized production containers
- **GitHub Actions** - Automate testing and deployment

### DevOps Practices

- Infrastructure as code
- Continuous integration and deployment
- Environment variable management
- Secret management
- Monitoring and logging

### Cost Management

- Understanding Azure pricing
- Free tier limits
- Cost optimization strategies
- Resource cleanup

## Prerequisites Check

Before starting, you'll need:

✅ **Docker Desktop** - For building containers
✅ **Git** - For version control
✅ **VS Code** (recommended) - For editing code
✅ **Azure Account** - Free tier available
✅ **Azure CLI** - For managing Azure resources
✅ **GitHub Account** - For CI/CD

**Don't have these yet?** → Continue to [Tutorial 02: Prerequisites](./02-prerequisites.md)

**Already set up?** → Skip to [Tutorial 03: Local Setup](./03-local-setup.md)

## Time Estimate

- **Reading tutorials**: 1-2 hours
- **Hands-on exercises**: 2-4 hours
- **Total**: 3-6 hours (can be split across sessions)

## Cost Estimate

### Azure Free Tier

Azure offers generous free tier for Container Apps:

**Free per month**:
- 180,000 vCPU-seconds
- 360,000 GB-seconds of memory
- 2 million HTTP requests

**What this means**:
- Small personal project: **FREE**
- Low-traffic API: **$0-5/month**
- Medium-traffic API: **$10-20/month**

**Cost optimization tips included in tutorials!**

## Support and Help

### Throughout the Tutorials

- **💡 Tips** - Best practices and optimization advice
- **⚠️ Warnings** - Common mistakes to avoid
- **🔍 Details** - In-depth explanations
- **🎯 Goals** - Clear objectives for each section

### If You Get Stuck

1. Check the troubleshooting section in each tutorial
2. Review the [troubleshooting.md](./troubleshooting.md) guide
3. Check Azure documentation links provided
4. Open an issue on GitHub

## Comparison with Other Platforms

Already familiar with Google Cloud Run? Here's how Azure Container Apps compares:

| Feature | Azure Container Apps | Google Cloud Run |
|---------|---------------------|------------------|
| **Pricing** | Free tier: 180k vCPU-sec | Free tier: 180k vCPU-sec |
| **Auto-scaling** | 0-300 instances | 0-1000 instances |
| **Custom domains** | Yes (free) | Yes (free) |
| **HTTPS** | Automatic | Automatic |
| **WebSockets** | Yes | Yes |
| **Max request timeout** | 300s | 3600s |
| **Container registries** | ACR, Docker Hub, GitHub | Artifact Registry, GCR |

**Both are excellent choices!** This tutorial focuses on Azure, but concepts transfer easily.

## What's Next?

Ready to start? Continue to:

→ **[Tutorial 02: Prerequisites](./02-prerequisites.md)** - Install required tools

Already have tools installed?

→ **[Tutorial 03: Local Setup](./03-local-setup.md)** - Get the app running locally

## Alternative Learning Paths

### I Want to Deploy Immediately

Skip tutorials 03-04 and go straight to:
- **[Tutorial 05: Manual Deployment](./05-manual-deployment.md)**

You'll learn, but might miss some context.

### I Want to Understand Everything First

Read all tutorials 01-04 before deploying:
- Builds solid foundation
- Recommended for beginners
- Better long-term understanding

### I Just Want CI/CD

Complete tutorials 01-05, then jump to:
- **[Tutorial 06: CI/CD Setup](./06-cicd-setup.md)**

## Repository Structure

This tutorial uses the **azure** branch:

```
├── src/                    # FastAPI application code
├── docs/                   # General documentation
├── docs/tutorials/         # Tutorial series (you are here)
├── scripts/                # Helper scripts for Azure
├── Dockerfile.dev          # Development container
├── Dockerfile.prod         # Production container
└── .github/workflows/      # CI/CD configuration
```

**Other branches**:
- **main** - Cloud-agnostic base
- **gcloud** - Google Cloud Run version
- **azure** - Azure Container Apps (you are here)
- **gcloud-starter** - Learning version with TODO markers
- **azure-starter** - Learning version (coming soon)

---

**Ready to begin?** → [Tutorial 02: Prerequisites](./02-prerequisites.md)

**Questions?** → Check [troubleshooting.md](./troubleshooting.md)
