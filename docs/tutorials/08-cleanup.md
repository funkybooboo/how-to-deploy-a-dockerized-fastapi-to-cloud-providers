# Tutorial 08: Cleanup and Resource Management

## Overview

Learn how to properly clean up Azure resources to avoid unexpected charges. This tutorial covers safe deletion practices and cost management.

**Time**: 10 minutes

**Important**: Follow these steps carefully to ensure complete cleanup and avoid ongoing charges.

## Quick Cleanup (Recommended)

The fastest way to remove all resources:

```bash
# Delete entire resource group
az group delete \
  --name fastapi-rg \
  --yes \
  --no-wait

# Verify deletion started
az group list --output table | grep fastapi
```

**What this deletes**:
- Container App (`fastapi-app`)
- Container Apps Environment (`fastapi-env`)
- Container Registry (`fastapiregistry`)
- All associated networking and logging resources

**Time**: 5-10 minutes for complete deletion

**💡 Benefit**: One command removes everything. No risk of leaving resources behind.

## Selective Cleanup

If you want to keep some resources and delete others:

### Delete Container App Only

```bash
# Delete the container app
az containerapp delete \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --yes

# Verify deletion
az containerapp list --resource-group fastapi-rg --output table
```

**Keeps**: Container Registry, Container Apps Environment
**Saves**: ~$0.03/hour (container app costs)
**Keeps charging**: ~$5/month (ACR Basic SKU)

### Delete Container Apps Environment

```bash
# Delete environment
az containerapp env delete \
  --name fastapi-env \
  --resource-group fastapi-rg \
  --yes

# Verify deletion
az containerapp env list --resource-group fastapi-rg --output table
```

**Required**: Must delete all container apps in environment first

### Delete Container Registry

```bash
# Delete ACR
az acr delete \
  --name fastapiregistry \
  --resource-group fastapi-rg \
  --yes

# Verify deletion
az acr list --resource-group fastapi-rg --output table
```

**Saves**: $5/month (Basic SKU) + $0.10/GB storage

## Verify Complete Cleanup

### Check Resources

```bash
# List remaining resources in resource group
az resource list \
  --resource-group fastapi-rg \
  --output table

# If empty, delete the resource group
az group delete --name fastapi-rg --yes
```

### Check Billing

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to **Cost Management + Billing**
3. Select **Cost analysis**
4. Filter by Resource Group = `fastapi-rg`
5. Verify no future charges are projected

## Cost Breakdown

### Active Deployment Costs

**Container App** (with --min-replicas 0):
- Idle: $0/hour
- 1 replica active: ~$0.03/hour
- 10 replicas active: ~$0.30/hour

**Container Apps Environment**:
- Included with container app usage

**Azure Container Registry** (Basic SKU):
- $0.167/day = ~$5/month
- Plus $0.10/GB/month for storage

**Example monthly costs**:
- Low traffic (mostly idle): $5-10/month
- Medium traffic (few hours/day): $15-25/month
- High traffic (always active): $50-100/month

### Free Tier Limits

Azure Container Apps includes:
- 180,000 vCPU-seconds/month FREE
- 360,000 GB-seconds/month FREE

**What this means**:
- ~50 hours of 1-replica runtime FREE
- Perfect for personal projects and learning

## Cleanup Best Practices

### 1. Use Tags for Easy Tracking

Tag resources when creating:

```bash
az group create \
  --name fastapi-rg \
  --location eastus \
  --tags environment=development project=fastapi

# Find all resources with tag
az resource list --tag project=fastapi --output table
```

### 2. Set Budget Alerts

Prevent surprise charges:

```bash
# Create budget alert
az consumption budget create \
  --budget-name fastapi-budget \
  --resource-group fastapi-rg \
  --amount 20 \
  --time-grain Monthly \
  --time-period start-date=2024-01-01 \
  --notifications \
    threshold=80 \
    operator=GreaterThan \
    contact-emails=your-email@example.com
```

### 3. Use Auto-shutdown for Dev

For development, scale to zero when not in use:

```bash
# Already configured with --min-replicas 0
# Automatically scales to zero after no traffic

# Or manually scale down
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --min-replicas 0 \
  --max-replicas 1
```

### 4. Regular Cleanup Audits

Schedule periodic checks:

```bash
#!/bin/bash
# cleanup-audit.sh

echo "=== Azure Resources Audit ==="
echo ""

echo "Resource Groups:"
az group list --output table

echo ""
echo "Container Apps:"
az containerapp list --output table

echo ""
echo "Container Registries:"
az acr list --output table

echo ""
echo "Estimated monthly cost: Check Azure Portal → Cost Management"
```

## Cleaning Up GitHub Actions

### Remove GitHub Secrets

If you're done with the project:

1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. Delete:
   - `AZURE_CREDENTIALS`
   - `ACR_USERNAME`
   - `ACR_PASSWORD`

### Delete Service Principal

```bash
# List service principals
az ad sp list --display-name github-actions-fastapi --output table

# Delete service principal
az ad sp delete --id <service-principal-object-id>
```

## Reactivation

Want to redeploy later? You'll need to recreate:

```bash
# 1. Create resource group
az group create --name fastapi-rg --location eastus

# 2. Create ACR
az acr create \
  --resource-group fastapi-rg \
  --name fastapiregistry \
  --sku Basic \
  --admin-enabled true

# 3. Create Container Apps Environment
az containerapp env create \
  --name fastapi-env \
  --resource-group fastapi-rg \
  --location eastus

# 4. Deploy (see Tutorial 05)
```

**💡 Pro tip**: Save your deployment commands in a script for easy reactivation!

## Common Cleanup Mistakes

### ❌ Mistake 1: Deleting Container App But Not ACR

**Problem**: Container app deleted but ACR still costs $5/month

**Solution**: Delete ACR too, or delete entire resource group

### ❌ Mistake 2: Leaving Min Replicas > 0

**Problem**: App scaled down but still charges for 1 replica

**Solution**: Set `--min-replicas 0` or delete completely

### ❌ Mistake 3: Not Verifying Deletion

**Problem**: Deletion command failed silently, resources still exist

**Solution**: Always verify with `az resource list`

### ❌ Mistake 4: Forgetting Application Insights

**Problem**: Deleted main resources but Application Insights still charging

**Solution**: Delete entire resource group to catch all resources

## Final Checklist

Before considering cleanup complete:

- [ ] Run `az resource list --resource-group fastapi-rg`
- [ ] Verify output is empty or shows only expected resources
- [ ] Check Azure Portal → Cost Management for projected charges
- [ ] Delete resource group if no longer needed
- [ ] Remove GitHub secrets (optional)
- [ ] Delete service principal (optional)
- [ ] Verify no workflows are still running (GitHub Actions tab)

## Cost Comparison: Keep vs Delete

### Scenario: Learning Project (1 month)

**Option A: Keep Everything Running**
- Container App (min=1): $22/month
- ACR (Basic): $5/month
- **Total**: ~$27/month

**Option B: Scale to Zero**
- Container App (min=0, occasional use): $2-5/month
- ACR (Basic): $5/month
- **Total**: ~$7-10/month

**Option C: Delete Everything**
- **Total**: $0/month

### Scenario: Production App

**Keep it running** if:
- Users depend on it
- You need <100ms response times
- Cost is acceptable for your use case

**Scale to zero** if:
- Personal project
- Low traffic
- Cold starts acceptable

**Delete it** if:
- Done learning
- Migrating to different platform
- Experimenting only

## Troubleshooting Deletion

### Error: "Resource has dependent resources"

**Problem**: Can't delete because other resources depend on it

**Solution**: Delete in this order:
1. Container Apps
2. Container Apps Environment
3. Container Registry
4. Resource Group

### Error: "Operation returned an invalid status code 'Conflict'"

**Problem**: Resource is locked or being updated

**Solutions**:
```bash
# Wait a few minutes and try again

# Check for locks
az lock list --resource-group fastapi-rg

# Remove lock if exists
az lock delete --name <lock-name> --resource-group fastapi-rg
```

### Deletion Taking Too Long

**Problem**: `az group delete` running for >15 minutes

**This is normal** for resource groups with many resources.

**Check status**:
```bash
# Check if resource group still exists
az group exists --name fastapi-rg

# List remaining resources
az resource list --resource-group fastapi-rg --output table
```

## Summary

You now know how to:
- ✅ Quickly delete all resources with one command
- ✅ Selectively delete specific resources
- ✅ Verify complete cleanup
- ✅ Understand cost implications
- ✅ Set up budget alerts
- ✅ Avoid common cleanup mistakes

## What You've Accomplished

Congratulations on completing the tutorial series! 🎉

You've learned:
- ✅ FastAPI application development
- ✅ Docker containerization
- ✅ Azure Container Apps deployment
- ✅ Azure Container Registry management
- ✅ CI/CD with GitHub Actions
- ✅ Monitoring and debugging
- ✅ Cost management and cleanup

## Next Steps

### Continue Learning

- Deploy to other platforms (GCloud, AWS)
- Add a database (Azure SQL, Cosmos DB)
- Implement authentication (Azure AD)
- Add custom domains
- Set up monitoring dashboards

### Real Projects

- Build and deploy your own API
- Create a microservices architecture
- Deploy a production application
- Contribute to open source

### Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## Final Words

Remember to clean up resources when done learning to avoid charges. Azure's free tier is generous, but resources left running will eventually cost money.

**Happy coding!** 🚀

---

**Need help?** Check [troubleshooting.md](./troubleshooting.md)

**Start over?** Go back to [Tutorial 01: Overview](./01-overview.md)
