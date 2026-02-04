# Tutorial 05: Manual Deployment to Azure Container Apps

## Overview

In this tutorial, you'll manually deploy your FastAPI application to Azure Container Apps using the Azure CLI. This step-by-step process teaches you exactly how deployment works before automating it with CI/CD.

**Time**: 1-2 hours

**What you'll do**:
1. Set up Azure resources (Resource Group, Container Registry, Container Apps Environment)
2. Build and push your Docker image to Azure Container Registry
3. Deploy to Azure Container Apps
4. Test your live application

## Prerequisites

- Completed [Tutorial 03: Local Setup](./03-local-setup.md)
- Azure CLI installed and authenticated
- Docker Desktop running
- Azure account with an active subscription

## Architecture Overview

```
 ┌─────────────────────────────────────────────────────────┐
 │                     Azure Subscription                   │
 │                                                           │
 │  ┌──────────────────────────────────────────────────┐  │
 │  │          Resource Group (fastapi-rg)              │  │
 │  │                                                    │  │
 │  │  ┌──────────────────────────────────────────┐   │  │
 │  │  │  Azure Container Registry (ACR)          │   │  │
 │  │  │  - Stores Docker images                  │   │  │
 │  │  └──────────────────────────────────────────┘   │  │
 │  │                      │                            │  │
 │  │                      ▼                            │  │
 │  │  ┌──────────────────────────────────────────┐   │  │
 │  │  │  Container Apps Environment              │   │  │
 │  │  │  - Shared infrastructure                 │   │  │
 │  │  │                                           │   │  │
 │  │  │  ┌──────────────────────────────────┐   │   │  │
 │  │  │  │  Container App (fastapi-app)     │   │   │  │
 │  │  │  │  - Your FastAPI service          │   │   │  │
 │  │  │  │  - Auto-scaling: 0-10 instances  │   │   │  │
 │  │  │  └──────────────────────────────────┘   │   │  │
 │  │  └──────────────────────────────────────────┘   │  │
 │  └──────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────┘
                          │
                          ▼
               HTTPS://your-app.azurecontainerapps.io
```

## Step 1: Authenticate with Azure

First, ensure you're logged in to Azure:

```bash
# Login to Azure (opens browser)
az login

# Verify you're logged in
az account show

# List available subscriptions
az account list --output table

# Set active subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

**💡 Tip**: Copy your subscription ID for later use.

## Step 2: Set Environment Variables

Define variables for consistent naming:

```bash
# Required variables
export RESOURCE_GROUP="fastapi-rg"
export LOCATION="eastus"
export ACR_NAME="fastapiregistry"  # Must be globally unique, lowercase, no hyphens
export CONTAINER_APP_NAME="fastapi-app"
export CONTAINER_APP_ENV="fastapi-env"

# Verify variables are set
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "ACR Name: $ACR_NAME"
echo "Container App: $CONTAINER_APP_NAME"
echo "Environment: $CONTAINER_APP_ENV"
```

**⚠️ Important**: `ACR_NAME` must be globally unique across all Azure users. Add your initials or a random number if needed:
- ✅ Good: `fastapiregistry123`, `jdoefastapi`
- ❌ Bad: `fastapi-registry` (hyphens not allowed), `FastAPI` (uppercase not allowed)

## Step 3: Create Resource Group

A Resource Group is a container for related Azure resources:

```bash
# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Verify creation
az group show --name $RESOURCE_GROUP
```

**💡 What is a Resource Group?**
- Logical container for Azure resources
- All resources in this tutorial go in one group
- Makes cleanup easy - delete the group to remove everything

## Step 4: Create Azure Container Registry (ACR)

ACR stores your private Docker images:

```bash
# Create container registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --location $LOCATION \
  --admin-enabled true

# Verify creation
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP
```

**🔍 Details**:
- `--sku Basic`: Lowest cost tier ($0.167/day), sufficient for small projects
- `--admin-enabled true`: Allows authentication with username/password (needed for deployment)
- SKU options: Basic ($5/month), Standard ($20/month), Premium ($100/month)

## Step 5: Authenticate Docker with ACR

Configure Docker to push images to your registry:

```bash
# Login to ACR
az acr login --name $ACR_NAME

# Verify login
az acr list --output table
```

**💡 What this does**: Configures Docker to use Azure credentials when pushing to `$ACR_NAME.azurecr.io`

## Step 6: Build Docker Image

Build your production Docker image:

```bash
# Build image with ACR tag
docker build -f Dockerfile.prod -t $ACR_NAME.azurecr.io/fastapi:latest .

# Verify image was built
docker images | grep fastapi
```

**Expected output**:
```
fastapiregistry.azurecr.io/fastapi   latest   abc123def456   10 seconds ago   164MB
```

**🔍 Image naming**:
- Format: `{registry-name}.azurecr.io/{image-name}:{tag}`
- Example: `fastapiregistry.azurecr.io/fastapi:latest`
- The registry name prefix tells Docker where to push

## Step 7: Push Image to ACR

Upload your image to Azure Container Registry:

```bash
# Push image
docker push $ACR_NAME.azurecr.io/fastapi:latest

# Verify push succeeded
az acr repository list --name $ACR_NAME --output table

# Check image tags
az acr repository show-tags --name $ACR_NAME --repository fastapi --output table
```

**Expected output**:
```
Result
--------
fastapi

Name
------
latest
```

**💡 Tip**: First push takes longest (uploads all layers). Subsequent pushes are faster (only changed layers).

## Step 8: Create Container Apps Environment

The environment is shared infrastructure for your container apps:

```bash
# Create container apps environment
az containerapp env create \
  --name $CONTAINER_APP_ENV \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Verify creation
az containerapp env show \
  --name $CONTAINER_APP_ENV \
  --resource-group $RESOURCE_GROUP
```

**🔍 What is a Container Apps Environment?**
- Shared network and compute infrastructure
- Multiple container apps can share one environment
- Provides logging and monitoring
- Acts like a Kubernetes cluster (but managed for you)

**💰 Cost**: ~$0.000024/vCPU-second, ~$0.000003/GB-second (when apps are running)

## Step 9: Get ACR Credentials

Retrieve credentials for the container app to pull images:

```bash
# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)

# Get ACR admin username
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)

# Get ACR admin password
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Verify credentials are set
echo "ACR Server: $ACR_LOGIN_SERVER"
echo "ACR Username: $ACR_USERNAME"
echo "ACR Password: ${ACR_PASSWORD:0:5}..." # Only show first 5 chars
```

## Step 10: Deploy Container App

Deploy your FastAPI application to Azure Container Apps:

```bash
# Create container app
az containerapp create \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINER_APP_ENV \
  --image $ACR_LOGIN_SERVER/fastapi:latest \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 8080 \
  --ingress external \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 0 \
  --max-replicas 10 \
  --env-vars \
    ENVIRONMENT=production \
    DEBUG=false \
    LOG_LEVEL=INFO \
    CORS_ORIGINS="*"

# Verify deployment
az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP
```

**🔍 Command Breakdown**:
- `--image`: Your Docker image from ACR
- `--registry-*`: ACR credentials for pulling the image
- `--target-port 8080`: Port your app listens on (must match Dockerfile)
- `--ingress external`: Makes app accessible from internet
- `--cpu 0.5`: 0.5 vCPU per instance (can be 0.25, 0.5, 0.75, 1.0, etc.)
- `--memory 1Gi`: 1GB RAM per instance
- `--min-replicas 0`: Scales to zero when idle (saves money!)
- `--max-replicas 10`: Maximum instances under load
- `--env-vars`: Environment variables for your app

**💰 Cost with these settings**:
- Idle (0 replicas): $0/hour
- 1 replica running: ~$0.03/hour
- 10 replicas running: ~$0.30/hour

## Step 11: Get Application URL

Retrieve your application's public URL:

```bash
# Get application URL
FQDN=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ Deployment Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 Application URL: https://$FQDN"
echo ""
echo "📍 Test Endpoints:"
echo "   Root:    https://$FQDN/"
echo "   Health:  https://$FQDN/api/health"
echo "   Hello:   https://$FQDN/api/hello"
echo "   Docs:    https://$FQDN/api/docs"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""
```

## Step 12: Test Your Deployment

Test all endpoints to verify everything works:

```bash
# Test root endpoint
curl https://$FQDN/

# Test health check
curl https://$FQDN/api/health

# Test hello endpoint
curl https://$FQDN/api/hello

# Test with name
curl https://$FQDN/api/hello/YourName
```

**Expected responses**:

**Root (`/`)**:
```json
{
  "message": "OK 🚀",
  "version": "1.0.0",
  "environment": "production"
}
```

**Health (`/api/health`)**:
```json
{
  "status": "healthy",
  "message": "OK"
}
```

**Hello (`/api/hello`)**:
```json
{
  "message": "Hello, World!"
}
```

### Test Interactive Documentation

Open in your browser:
```
https://your-app-url.azurecontainerapps.io/api/docs
```

Try the API directly from Swagger UI!

## Step 13: View Logs

Check your application logs:

```bash
# Stream live logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --follow

# View recent logs (last 50 lines)
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --tail 50
```

**💡 Tip**: Keep logs streaming in a separate terminal while you test.

## Step 14: Monitor Your Application

### View Metrics in Azure Portal

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to Resource Groups → `fastapi-rg`
3. Click on your container app
4. Select "Metrics" to see:
   - Request count
   - Response time
   - CPU usage
   - Memory usage
   - Replica count

### CLI Metrics

```bash
# Show app details including metrics
az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties
```

## Troubleshooting

### Image Pull Errors

**Problem**: "Failed to pull image"

**Solutions**:
```bash
# Verify ACR credentials
az acr credential show --name $ACR_NAME

# Test image exists
az acr repository show --name $ACR_NAME --repository fastapi

# Recreate container app with correct credentials
az containerapp delete --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP
# Then re-run Step 10
```

### App Not Responding

**Problem**: URL returns 502 or times out

**Solutions**:
```bash
# Check if replicas are running
az containerapp replica list \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP

# Check logs for errors
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --tail 100

# Verify target port matches Dockerfile
# Dockerfile exposes 8080, deployment must use --target-port 8080
```

### Container Won't Start

**Problem**: Replicas keep restarting

**Checks**:
1. Logs show the actual error:
   ```bash
   az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --tail 100
   ```

2. Common issues:
   - Wrong port in Dockerfile vs deployment
   - Missing environment variables
   - App crashes on startup
   - Health checks failing

### ACR Name Already Taken

**Problem**: "The registry name is already taken"

**Solution**: Choose a different name:
```bash
export ACR_NAME="fastapiregistry$(date +%s)"  # Adds timestamp
# Or add your initials: export ACR_NAME="jdoefastapi"
```

## Cost Management

### Current Costs

Check what you're being charged:

```bash
# View resource costs (requires billing access)
az consumption usage list --output table
```

Or visit [Azure Cost Management](https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis)

### Reduce Costs

**Scale to zero when not in use**:
- Your deployment already uses `--min-replicas 0`
- App scales to zero after no requests for a few minutes
- First request after scaling to zero takes ~5 seconds (cold start)

**Use lower SKU for ACR**:
- Basic SKU ($5/month) is sufficient for small projects
- Storage costs extra: $0.10/GB/month

**Delete when done**:
```bash
# Delete entire resource group (removes everything)
az group delete --name $RESOURCE_GROUP --yes
```

## Updating Your Deployment

When you make code changes:

```bash
# 1. Rebuild image
docker build -f Dockerfile.prod -t $ACR_NAME.azurecr.io/fastapi:latest .

# 2. Push new version
docker push $ACR_NAME.azurecr.io/fastapi:latest

# 3. Update container app (triggers deployment)
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_LOGIN_SERVER/fastapi:latest
```

**💡 Tip**: Updates are rolling - zero downtime!

## Next Steps

Congratulations! Your FastAPI app is live on Azure! 🎉

### What You've Learned

- ✅ Azure resource management (Resource Groups, ACR, Container Apps)
- ✅ Docker image building and pushing
- ✅ Container app deployment and configuration
- ✅ Auto-scaling configuration
- ✅ Environment variable management
- ✅ Basic monitoring and logging

### Continue Learning

- **[Tutorial 06: CI/CD Setup](./06-cicd-setup.md)** - Automate deployment with GitHub Actions
- **[Tutorial 07: Monitoring](./07-monitoring.md)** - Advanced monitoring and debugging
- **[Tutorial 08: Cleanup](./08-cleanup.md)** - Remove resources to avoid charges

### Quick Reference Commands

```bash
# View all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# View container app details
az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP

# Stream logs
az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --follow

# Update app
az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP

# Delete everything
az group delete --name $RESOURCE_GROUP --yes
```

## Summary

You've successfully:
1. ✅ Created Azure resources (Resource Group, ACR, Container Apps Environment)
2. ✅ Built and pushed a Docker image to ACR
3. ✅ Deployed your FastAPI app to Azure Container Apps
4. ✅ Configured auto-scaling (0-10 replicas)
5. ✅ Tested your live application
6. ✅ Learned to view logs and monitor your app

Your application is now live at: `https://your-app.azurecontainerapps.io`

**Ready to automate?** → [Tutorial 06: CI/CD Setup](./06-cicd-setup.md)
