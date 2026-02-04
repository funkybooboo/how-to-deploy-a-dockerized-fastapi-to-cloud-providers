# Troubleshooting Guide - Azure Container Apps

Quick solutions to common problems encountered while deploying FastAPI to Azure Container Apps.

## Table of Contents

- [Azure CLI Issues](#azure-cli-issues)
- [Docker Issues](#docker-issues)
- [Azure Container Registry Issues](#azure-container-registry-issues)
- [Container App Issues](#container-app-issues)
- [CI/CD Issues](#cicd-issues)
- [Performance Issues](#performance-issues)
- [Cost Issues](#cost-issues)

## Azure CLI Issues

### az command not found

**Symptoms**: `bash: az: command not found`

**Solutions**:
```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download MSI from https://docs.microsoft.com/cli/azure/install-azure-cli

# Verify installation
az --version
```

### Not logged in to Azure

**Symptoms**: "Please run 'az login' to setup account"

**Solutions**:
```bash
# Login (opens browser)
az login

# Verify login
az account show

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "Your Subscription Name"
```

### Permission denied errors

**Symptoms**: "The client does not have authorization to perform action"

**Solutions**:
```bash
# Check your role
az role assignment list --assignee your-email@example.com --output table

# You need at least "Contributor" role on the subscription or resource group
# Contact your Azure administrator if you lack permissions
```

## Docker Issues

### Docker daemon not running

**Symptoms**: "Cannot connect to the Docker daemon"

**Solutions**:
- **macOS/Windows**: Start Docker Desktop application
- **Linux**: `sudo systemctl start docker`
- Verify: `docker info`

### Image build fails

**Symptoms**: "ERROR: failed to solve"

**Solutions**:
```bash
# Clear Docker build cache
docker builder prune -a

# Build with --no-cache flag
docker build --no-cache -f Dockerfile.prod -t myapp:latest .

# Check Dockerfile syntax
# Common issues:
# - Missing dependencies in requirements.txt
# - Incorrect file paths in COPY commands
# - Wrong base image version
```

### Permission denied on Linux

**Symptoms**: "Got permission denied while trying to connect to the Docker daemon socket"

**Solutions**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or use: newgrp docker

# Verify
docker ps
```

## Azure Container Registry Issues

### ACR name already taken

**Symptoms**: "The registry name 'X' is already taken"

**Solutions**:
```bash
# ACR names must be globally unique
# Try adding a suffix
export ACR_NAME="fastapiregistry$(date +%s)"

# Or use your initials
export ACR_NAME="jdoefastapi"

# Verify uniqueness
az acr check-name --name $ACR_NAME
```

### ACR login failed

**Symptoms**: "Failed to authenticate with Azure Container Registry"

**Solutions**:
```bash
# Re-login to ACR
az acr login --name $ACR_NAME

# Verify ACR exists
az acr show --name $ACR_NAME

# Check if you have access
az acr show --name $ACR_NAME --query id
```

### Image push denied

**Symptoms**: "denied: requested access to the resource is denied"

**Solutions**:
```bash
# Ensure admin is enabled
az acr update --name $ACR_NAME --admin-enabled true

# Verify you're logged in
az acr login --name $ACR_NAME

# Check image name format
# Must be: {acr-name}.azurecr.io/{image}:{tag}
# Example: fastapiregistry.azurecr.io/fastapi:latest
```

### Image not found in ACR

**Symptoms**: "repository does not exist or may require authentication"

**Solutions**:
```bash
# List repositories
az acr repository list --name $ACR_NAME --output table

# List tags for a repository
az acr repository show-tags --name $ACR_NAME --repository fastapi --output table

# Verify you pushed the image
docker push $ACR_NAME.azurecr.io/fastapi:latest
```

## Container App Issues

### Container App returns 502

**Symptoms**: URL returns "502 Bad Gateway"

**Diagnosis**:
```bash
# Check replica status
az containerapp replica list \
  --name fastapi-app \
  --resource-group fastapi-rg

# Check logs for errors
az containerapp logs show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --tail 100
```

**Common causes and solutions**:

**1. Wrong target port**:
```bash
# Fix: Update target port to match Dockerfile
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --target-port 8080
```

**2. App crashes on startup**:
- Check logs for Python errors
- Verify all dependencies in requirements.txt
- Test image locally: `docker run -p 8080:8080 $ACR_NAME.azurecr.io/fastapi:latest`

**3. Resource limits too low**:
```bash
# Increase CPU and memory
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --cpu 1.0 \
  --memory 2Gi
```

### Slow cold starts

**Symptoms**: First request after idle takes 5-10 seconds

**This is expected!** Container Apps scale to zero.

**Solutions**:
```bash
# Option 1: Keep minimum replicas (costs more)
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --min-replicas 1

# Option 2: Optimize Docker image
# - Use smaller base image
# - Reduce layers
# - Multi-stage builds
```

### Container keeps restarting

**Symptoms**: Replicas restart every few minutes

**Diagnosis**:
```bash
# Check logs for crash reason
az containerapp logs show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --tail 200

# Common issues:
# - Out of memory (OOMKilled)
# - Unhandled exceptions
# - Health check failures
```

**Solutions**:
```bash
# For OOMKilled:
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --memory 2Gi

# For app crashes:
# Fix the bug in your code
# Test locally first:
docker run -p 8080:8080 your-image:latest
```

### Environment variables not working

**Symptoms**: App can't read environment variables

**Solutions**:
```bash
# Verify variables are set
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.template.containers[0].env

# Update variables
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --set-env-vars KEY=VALUE KEY2=VALUE2

# For secrets (sensitive data):
az containerapp secret set \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --secrets "db-password=secretvalue"
```

## CI/CD Issues

### GitHub Actions: Invalid Azure credentials

**Symptoms**: "AADSTS700016: Application with identifier 'X' was not found"

**Solutions**:
```bash
# Recreate service principal
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

az ad sp create-for-rbac \
  --name "github-actions-fastapi-new" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/fastapi-rg \
  --sdk-auth

# Copy output and update AZURE_CREDENTIALS secret in GitHub
```

### GitHub Actions: Workflow doesn't trigger

**Symptoms**: Push to azure branch doesn't start workflow

**Checks**:
1. Workflow file in `.github/workflows/cd.yaml`?
2. YAML syntax valid? (check Actions tab for errors)
3. Pushed to correct branch (`azure`)?
4. Any branch protection rules?

**Debug**:
```yaml
# Add to workflow for debugging
on:
  push:
    branches: [ azure ]
  workflow_dispatch:  # Allows manual trigger

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Workflow triggered!"
```

### GitHub Actions: Image push fails

**Symptoms**: "denied: requested access to the resource is denied"

**Solutions**:
```bash
# Give service principal ACR access
SP_CLIENT_ID="<your-service-principal-client-id>"

az role assignment create \
  --assignee $SP_CLIENT_ID \
  --role AcrPush \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/fastapi-rg/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME
```

## Performance Issues

### High response times

**Symptoms**: API responses take >1 second

**Diagnosis**:
```bash
# Check if CPU/memory constrained
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.template.containers[0].resources
```

**Solutions**:
```bash
# Increase resources
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --cpu 1.0 \
  --memory 2Gi

# Add more replicas
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --max-replicas 20
```

### Scaling not working

**Symptoms**: App doesn't scale under load

**Solutions**:
```bash
# Check scaling rules
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.template.scale

# Add/update HTTP scaling rule
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-metadata concurrentRequests=50
```

## Cost Issues

### Unexpected charges

**Symptoms**: Bill higher than expected

**Diagnosis**:
1. Go to Azure Portal → Cost Management
2. View cost analysis
3. Filter by Resource Group = `fastapi-rg`
4. Check which resources are charging

**Common causes**:
- **Min replicas > 0**: Always running, always charging
- **Large ACR images**: Storage costs ($0.10/GB/month)
- **High traffic**: More replica hours
- **Wrong SKU**: Premium instead of Basic

**Solutions**:
```bash
# Scale to zero when idle
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --min-replicas 0

# Delete unused ACR images
az acr repository delete \
  --name $ACR_NAME \
  --repository fastapi \
  --tag old-version \
  --yes

# Delete everything if done learning
az group delete --name fastapi-rg --yes
```

### Free tier exceeded

**Symptoms**: Charges despite "free tier" claims

**Understanding free tier**:
- 180,000 vCPU-seconds/month FREE
- 360,000 GB-seconds/month FREE
- **After that**: Pay per use

**Example calculations**:
- 1 replica (0.5 vCPU, 1GB RAM) running 24/7:
  - vCPU-seconds: 0.5 × 60 × 60 × 24 × 30 = 1,296,000 (exceeds free tier)
  - Charges apply!

**Solutions**:
- Scale to zero when idle (`--min-replicas 0`)
- Use smaller resources (`--cpu 0.25 --memory 0.5Gi`)
- Monitor usage in Cost Management

## Getting More Help

### Check Azure Service Health

```bash
# Check service health
az rest --method get --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2018-07-01"
```

Or visit: [Azure Status Dashboard](https://status.azure.com/)

### Enable Debug Logging

```bash
# Enable debug logging in CLI
az configure --defaults debug=true

# Run command again to see verbose output
az containerapp show --name fastapi-app --resource-group fastapi-rg
```

### Contact Support

- **Azure Support**: [azure.microsoft.com/support](https://azure.microsoft.com/support)
- **GitHub Issues**: Report bugs in this repository
- **Stack Overflow**: Tag questions with `azure-container-apps` and `fastapi`

## Quick Diagnostic Script

Save this as `diagnose.sh`:

```bash
#!/bin/bash
echo "=== Azure Container Apps Diagnostic ==="
echo ""

echo "1. Azure CLI Version:"
az --version | head -1

echo ""
echo "2. Current Subscription:"
az account show --query name -o tsv

echo ""
echo "3. Resource Group Resources:"
az resource list --resource-group fastapi-rg --output table

echo ""
echo "4. Container App Status:"
az containerapp show --name fastapi-app --resource-group fastapi-rg --query "{Name:name,Status:properties.provisioningState,URL:properties.configuration.ingress.fqdn}" -o table

echo ""
echo "5. Active Replicas:"
az containerapp replica list --name fastapi-app --resource-group fastapi-rg --output table

echo ""
echo "6. Recent Logs (last 20 lines):"
az containerapp logs show --name fastapi-app --resource-group fastapi-rg --tail 20
```

Run with: `bash diagnose.sh`

## Summary

Most issues fall into these categories:
- ✅ **Authentication**: Run `az login` and verify access
- ✅ **Resources**: Check if resources exist with correct names
- ✅ **Logs**: Always check logs first (`az containerapp logs show`)
- ✅ **Permissions**: Verify service principal has correct roles
- ✅ **Configuration**: Double-check resource names, ports, environment variables

**Still stuck?** Open an issue on GitHub with:
1. Error message (full text)
2. Command you ran
3. Output of `diagnose.sh`
4. What you've already tried
