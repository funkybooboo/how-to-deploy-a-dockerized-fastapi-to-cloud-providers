# Tutorial 06: CI/CD Setup with GitHub Actions

## Overview

Automate your deployment with GitHub Actions. Every push to the `azure` branch will automatically:
1. Run tests
2. Build Docker image
3. Push to Azure Container Registry
4. Deploy to Azure Container Apps

**Time**: 30-60 minutes

## Prerequisites

- Completed [Tutorial 05: Manual Deployment](./05-manual-deployment.md)
- GitHub account
- Repository pushed to GitHub
- Azure resources created (from Tutorial 05)

## Architecture

```
┌─────────────┐       ┌──────────────────┐       ┌──────────┐
│   GitHub    │       │ GitHub Actions   │       │   ACR    │
│ Repository  │──────▶│   Workflow       │──────▶│  (Push)  │
│ (Push code) │       │ (Build & Deploy) │       └──────────┘
└─────────────┘       └──────────────────┘             │
                                                        ▼
                      ┌──────────────────┐       ┌──────────┐
                      │  Container App   │◀──────│  Deploy  │
                      │   (Updated)      │       └──────────┘
                      └──────────────────┘
```

## Step 1: Create Azure Service Principal

A service principal allows GitHub Actions to manage your Azure resources.

```bash
# Set variables
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
RESOURCE_GROUP="fastapi-rg"

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-fastapi" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

**💡 Save the output!** You'll need it in the next step. It looks like:
```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx",
  ...
}
```

**🔒 Important**: This JSON contains sensitive credentials. Never commit it to your repository!

## Step 2: Add GitHub Secrets

### Navigate to GitHub Settings

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Add Required Secrets

**Secret 1: AZURE_CREDENTIALS**
- Name: `AZURE_CREDENTIALS`
- Value: Paste the entire JSON output from Step 1

**Secret 2: ACR_USERNAME** (optional, for flexibility)
```bash
# Get ACR username
az acr credential show --name fastapiregistry --query username --output tsv
```
- Name: `ACR_USERNAME`
- Value: Output from command above

**Secret 3: ACR_PASSWORD** (optional, for flexibility)
```bash
# Get ACR password
az acr credential show --name fastapiregistry --query passwords[0].value --output tsv
```
- Name: `ACR_PASSWORD`
- Value: Output from command above

## Step 3: Understand the Workflow

The workflow file `.github/workflows/cd.yaml` already exists in the azure branch. Let's understand what it does:

```yaml
name: Deploy to Azure Container Apps

env:
  AZURE_CONTAINER_APP: fastapi-app
  AZURE_RESOURCE_GROUP: fastapi-rg
  ACR_NAME: fastapiregistry
  AZURE_LOCATION: eastus

on:
  push:
    branches: [ azure ]  # Triggers on push to azure branch

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # 1. Checkout code
      - name: Checkout repository
        uses: actions/checkout@v3

      # 2. Login to Azure
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      # 3. Login to ACR
      - name: Login to Azure Container Registry
        run: az acr login --name ${{ env.ACR_NAME }}

      # 4. Build and push Docker image
      - name: Build and push Docker image
        run: |
          docker build -f Dockerfile.prod -t ${{ env.ACR_NAME }}.azurecr.io/fastapi:latest .
          docker push ${{ env.ACR_NAME }}.azurecr.io/fastapi:latest

      # 5. Deploy to Container Apps
      - name: Deploy to Azure Container Apps
        uses: azure/container-apps-deploy-action@v1
        with:
          acrName: ${{ env.ACR_NAME }}
          containerAppName: ${{ env.AZURE_CONTAINER_APP }}
          resourceGroup: ${{ env.AZURE_RESOURCE_GROUP }}
          imageToDeploy: ${{ env.ACR_NAME }}.azurecr.io/fastapi:latest
          targetPort: 8080
```

## Step 4: Update Workflow Variables

Edit `.github/workflows/cd.yaml` if your resource names are different:

```yaml
env:
  AZURE_CONTAINER_APP: fastapi-app        # Your container app name
  AZURE_RESOURCE_GROUP: fastapi-rg        # Your resource group name
  ACR_NAME: fastapiregistry               # Your ACR name (no .azurecr.io)
  AZURE_LOCATION: eastus                  # Your location
```

## Step 5: Test the Workflow

### Make a Code Change

```bash
# Make a small change
echo "# CI/CD Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test CI/CD pipeline"
git push origin azure
```

### Monitor the Workflow

1. Go to GitHub → **Actions** tab
2. You should see your workflow running
3. Click on it to see live logs
4. Wait for all steps to complete (2-5 minutes)

### Expected Output

```
✅ Checkout repository
✅ Azure Login
✅ Login to Azure Container Registry
✅ Build and push Docker image
✅ Deploy to Azure Container Apps
```

## Step 6: Verify Deployment

```bash
# Get container app URL
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.configuration.ingress.fqdn \
  --output tsv

# Test the deployment
curl https://your-app.azurecontainerapps.io/api/health
```

## Workflow Triggers

The workflow runs on:

**Push to azure branch**:
```bash
git push origin azure
```

**Manual trigger** (from GitHub Actions tab):
- Click "Run workflow" button

**Pull request** (optional, add to workflow):
```yaml
on:
  push:
    branches: [ azure ]
  pull_request:
    branches: [ azure ]
```

## Advanced: Adding Tests

Add a test job before deploying:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run tests
        run: pytest src/tests/ -v

  deploy:
    needs: test  # Only deploy if tests pass
    runs-on: ubuntu-latest
    # ... rest of deploy job
```

## Troubleshooting

### Error: "Invalid Azure credentials"

**Problem**: GitHub can't authenticate with Azure

**Solutions**:
```bash
# 1. Recreate service principal
az ad sp create-for-rbac --name "github-actions-fastapi" --sdk-auth

# 2. Update AZURE_CREDENTIALS secret in GitHub
# 3. Ensure JSON is valid (no extra characters)
```

### Error: "ACR login failed"

**Problem**: Can't access Container Registry

**Solutions**:
```bash
# Give service principal ACR access
az role assignment create \
  --assignee <service-principal-client-id> \
  --role AcrPush \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/fastapi-rg/providers/Microsoft.ContainerRegistry/registries/fastapiregistry
```

### Error: "Container app not found"

**Problem**: Deployment target doesn't exist

**Solutions**:
1. Verify resource names in workflow match your actual resources
2. Ensure you completed Tutorial 05 (manual deployment first)
3. Check resources exist:
   ```bash
   az containerapp list --resource-group fastapi-rg --output table
   ```

### Workflow Doesn't Trigger

**Problem**: Push doesn't start workflow

**Checks**:
1. Pushed to correct branch? (`azure`)
2. Workflow file in `.github/workflows/`?
3. YAML syntax valid? (check Actions tab for errors)
4. Branch protection rules blocking it?

## Best Practices

### 1. Use Environments

Create GitHub environments for staging/production:

```yaml
jobs:
  deploy:
    environment: production  # Requires manual approval
    runs-on: ubuntu-latest
```

### 2. Version Your Images

Use git commit SHA as tag:

```yaml
- name: Build and push
  run: |
    docker build -f Dockerfile.prod -t $ACR_NAME.azurecr.io/fastapi:${{ github.sha }} .
    docker push $ACR_NAME.azurecr.io/fastapi:${{ github.sha }}
```

### 3. Secure Secrets

- Never commit secrets to repository
- Rotate service principal credentials periodically
- Use minimal permissions (contributor only on resource group, not subscription)

### 4. Monitor Deployments

Add notifications:

```yaml
- name: Notify on failure
  if: failure()
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: 'Deployment failed',
        body: 'Check the workflow run for details.'
      })
```

## Cost Impact

GitHub Actions costs:
- **Public repos**: FREE (unlimited minutes)
- **Private repos**: 2,000 free minutes/month, then $0.008/minute

Typical workflow duration: 3-5 minutes
Cost per deployment (private repo): ~$0.03-0.04

Azure costs unchanged (same as manual deployment).

## Next Steps

Congratulations! You have full CI/CD automation! 🎉

### What You've Learned

- ✅ Azure service principal creation
- ✅ GitHub secrets management
- ✅ GitHub Actions workflows
- ✅ Automated testing and deployment
- ✅ Workflow troubleshooting

### Continue Learning

- **[Tutorial 07: Monitoring](./07-monitoring.md)** - Advanced monitoring and debugging
- **[Tutorial 08: Cleanup](./08-cleanup.md)** - Remove resources

### Workflow Examples

**Deploy on tag**:
```yaml
on:
  push:
    tags:
      - 'v*'
```

**Deploy multiple environments**:
```yaml
jobs:
  deploy-staging:
    # Deploy to staging
  deploy-production:
    needs: deploy-staging
    # Deploy to production
```

## Summary

You now have:
- ✅ Automated testing on every push
- ✅ Automated Docker builds
- ✅ Automated deployments to Azure
- ✅ Zero-downtime rolling updates
- ✅ Full audit trail in GitHub Actions

**Next**: Learn advanced monitoring → [Tutorial 07: Monitoring](./07-monitoring.md)
