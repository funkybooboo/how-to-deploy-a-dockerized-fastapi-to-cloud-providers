# Documentation Hub

Welcome to the FastAPI Multi-Cloud Deployment documentation! This hub helps you find exactly what you need, whether you're just starting out or deploying to production.

## 🎯 I Want To...

**Get Started Quickly**
- → **[Getting Started](./getting-started.md)** (15 min) - Install tools, run your first container, see live reload in action

**Understand the Application**
- → **[Application Guide](./application.md)** (10 min) - Learn the codebase structure, key components, and design decisions

**Develop Locally**
- → **[Development Guide](./development.md)** (20 min) - Set up Docker Compose, configure your editor, run tests

**Master Docker**
- → **[Docker Guide](./docker.md)** (45 min) - Deep dive into Dockerfiles, multi-stage builds, and optimization

**Use the API**
- → **[API Reference](./api-reference.md)** (10 min) - Explore endpoints, request/response formats, and examples

**Deploy to Cloud**
- → **[Cloud Deployment Branches](#cloud-deployment-guides)** - Platform-specific tutorials (GCloud, Azure)

## 📚 Learning Paths

### Beginner Path (1-2 hours)

**Goal**: Run the application locally and understand what it does

1. **[Getting Started](./getting-started.md)** (15 min)
   - Install Docker and VS Code
   - Open project in Dev Container
   - See FastAPI app running at http://localhost:8080

2. **[Application Guide](./application.md)** (10 min)
   - Understand the project structure
   - Learn what each endpoint does
   - See the automatic API docs

3. **[Development Guide](./development.md)** (20 min)
   - Use Docker Compose for development
   - Make code changes and see live reload
   - Run tests with pytest

**Next Steps**: Try modifying an endpoint or adding a new one!

### Intermediate Path (2-4 hours)

**Goal**: Understand Docker containerization and development workflow

Prerequisites: Complete Beginner Path

4. **[Docker Guide](./docker.md)** (45 min)
   - Understand Dockerfile.dev vs Dockerfile.prod
   - Learn about multi-stage builds
   - Optimize image size and build time

5. **[API Reference](./api-reference.md)** (10 min)
   - Explore all available endpoints
   - Understand request/response models
   - Try the interactive API docs

**Hands-On Project**: Build and run the production Docker image locally

### Advanced Path (4-8 hours)

**Goal**: Deploy to cloud and set up CI/CD

Prerequisites: Complete Intermediate Path

6. **Choose Your Cloud Platform**:
   - **[Google Cloud Run](../../tree/gcloud)** - 8 tutorials covering setup, deployment, CI/CD, monitoring
   - **[Azure Container Apps](../../tree/azure)** - 8 tutorials for Microsoft Azure

7. **Learn by Doing** (Optional):
   - **[GCloud-Starter](../../tree/gcloud-starter)** - Complete TODO markers to learn Google Cloud
   - **[Azure-Starter](../../tree/azure-starter)** - Complete TODO markers to learn Azure

**Hands-On Project**: Deploy your own modified version to production!

## 📖 Documentation Reference

### Core Guides

| Guide | Topics Covered | Reading Time |
|-------|---------------|--------------|
| **[Getting Started](./getting-started.md)** | Installation, Dev Containers, first run | 15 min |
| **[Application](./application.md)** | Project structure, code organization, FastAPI basics | 10 min |
| **[Development](./development.md)** | Docker Compose, testing, debugging, workflow | 20 min |
| **[Docker](./docker.md)** | Dockerfile deep-dive, multi-stage builds, optimization | 45 min |
| **[API Reference](./api-reference.md)** | Endpoints, models, examples, Swagger UI | 10 min |

### Quick Start Matrix

| Your Experience Level | Start Here | Then Read |
|----------------------|------------|-----------|
| **New to Everything** | Getting Started → Application | Development → Docker (basics) |
| **Know Python, New to Docker** | Getting Started → Docker | Development → API Reference |
| **Know Docker, New to FastAPI** | Application → API Reference | Development → Docker (advanced) |
| **Ready to Deploy** | Choose cloud branch | Follow tutorials in order |

## 🌐 Cloud Deployment Guides

### Main Branch (You Are Here)

**Cloud-agnostic base code** - Works on any platform

- ✅ FastAPI application with automatic API documentation
- ✅ Development and production Docker configurations
- ✅ Test suite with 91% coverage
- ✅ Complete development documentation

### Production Deployment Branches

**[Google Cloud Run (gcloud branch)](../../tree/gcloud)**
- 8 comprehensive tutorials
- Helper scripts for setup, deployment, cleanup
- GitHub Actions CI/CD workflow
- Complete troubleshooting guide

**[Microsoft Azure (azure branch)](../../tree/azure)**
- 8 comprehensive tutorials
- Azure Container Apps deployment
- GitHub Actions CI/CD workflow
- Azure-specific monitoring and debugging

### Learning Branches (Hands-On)

**[GCloud-Starter (gcloud-starter branch)](../../tree/gcloud-starter)**
- 34 TODO markers across 3 files
- Step-by-step hints and guidance
- Validation script to check progress
- Reset script to start over

**[Azure-Starter (azure-starter branch)](../../tree/azure-starter)**
- 40 TODO markers across 3 files
- Azure-specific learning path
- Complete hands-on experience
- Build real deployment automation

## 🎓 Topics Explained

### Application Architecture
- **Covered in**: [Application Guide](./application.md)
- Learn about: FastAPI structure, endpoint organization, configuration management

### Local Development
- **Covered in**: [Development Guide](./development.md)
- Learn about: Docker Compose, volume mounts, hot reload, testing workflow

### Containerization
- **Covered in**: [Docker Guide](./docker.md)
- Learn about: Multi-stage builds, image optimization, development vs production images

### API Design
- **Covered in**: [API Reference](./api-reference.md)
- Learn about: RESTful endpoints, Pydantic models, automatic documentation

## 💡 Tips for Using This Documentation

**First Time Here?**
- Start with [Getting Started](./getting-started.md)
- Follow the Beginner Path
- Don't skip steps - each builds on the previous

**Looking for Something Specific?**
- Use the "I Want To..." section above
- Check the Quick Start Matrix for your experience level

**Ready to Deploy?**
- Complete the Intermediate Path first
- Choose a cloud platform (GCloud or Azure)
- Follow the cloud-specific tutorials in order

**Learning by Doing?**
- Try the -starter branches for hands-on experience
- Complete TODO markers at your own pace
- Use validation scripts to check your work

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on how to contribute to this project.

---

**Need Help?** Open an issue on GitHub or check the troubleshooting guides in the cloud-specific branches.
