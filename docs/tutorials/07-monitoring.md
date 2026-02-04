# Tutorial 07: Monitoring and Debugging

## Overview

Learn to monitor your Azure Container Apps deployment, view logs, track metrics, and debug issues effectively.

**Time**: 30 minutes

## Monitoring Options

### 1. Azure Portal (Web UI)
- Visual dashboards
- Real-time metrics
- Log exploration
- Best for: Quick checks, visual analysis

### 2. Azure CLI (Terminal)
- Script-friendly
- CI/CD integration
- Best for: Automation, quick debugging

### 3. Application Insights (Optional)
- Advanced APM
- Distributed tracing
- Custom metrics
- Best for: Production monitoring

## Viewing Logs

### CLI - Stream Live Logs

```bash
# Stream logs in real-time
az containerapp logs show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --follow

# View recent logs
az containerapp logs show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --tail 100
```

**💡 Tip**: Keep logs streaming in a separate terminal while testing.

### Portal - Browse Logs

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to: Resource Groups → `fastapi-rg` → `fastapi-app`
3. Select **Log stream** (left menu)
4. View live logs in browser

### Understanding Log Output

**Successful request**:
```
INFO: 172.16.0.1:54321 - "GET /api/health HTTP/1.1" 200 OK
```

**Error**:
```
ERROR: Exception in ASGI application
Traceback (most recent call last):
  ...
```

**Startup**:
```
INFO: Started server process [1]
INFO: Waiting for application startup.
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:8080
```

## Monitoring Metrics

### CLI - View Replica Count

```bash
# List active replicas
az containerapp replica list \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --output table

# Show container app details
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.template
```

### Portal - Visual Metrics

1. Go to your container app in Azure Portal
2. Select **Metrics** (left menu)
3. Add metrics:
   - **Requests**: Total request count
   - **CPU Usage**: CPU consumption
   - **Memory Usage**: Memory consumption
   - **Replica Count**: Number of instances

**💡 Create a dashboard**: Pin metrics to a custom dashboard for quick access.

## Debugging Common Issues

### Issue: App Returns 502 Bad Gateway

**Symptoms**: URL returns 502 or times out

**Diagnosis**:
```bash
# Check if replicas are running
az containerapp replica list \
  --name fastapi-app \
  --resource-group fastapi-rg

# Check recent logs for errors
az containerapp logs show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --tail 50
```

**Common causes**:
1. **Wrong port**: Dockerfile exposes 8080, but deployment uses different `--target-port`
2. **App crashes on startup**: Check logs for Python errors
3. **Health check failures**: App takes too long to start

**Solutions**:
```bash
# Fix target port
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --target-port 8080

# Increase CPU/memory if app is resource-starved
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --cpu 1.0 \
  --memory 2Gi
```

### Issue: Slow Cold Starts

**Symptoms**: First request after idle takes 5-10 seconds

**This is normal!** Container Apps scale to zero, which means:
- No cost when idle
- But first request must:
  1. Start a new replica
  2. Pull container image
  3. Start your app
  4. Process the request

**Solutions**:
```bash
# Option 1: Keep minimum replicas (costs more)
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --min-replicas 1  # Always keep 1 instance running

# Option 2: Optimize your Docker image
# - Use smaller base image
# - Reduce dependencies
# - Pre-compile Python files
```

**💰 Cost comparison**:
- `--min-replicas 0`: $0/hour when idle, 5-10s cold start
- `--min-replicas 1`: ~$0.03/hour always, instant response

### Issue: High Memory Usage

**Symptoms**: Replicas restarting frequently

**Diagnosis**:
```bash
# Check resource limits
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query properties.template.containers[0].resources
```

**Solutions**:
```bash
# Increase memory limit
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --memory 2Gi  # Increase from 1Gi to 2Gi
```

### Issue: Image Pull Failures

**Symptoms**: "Failed to pull image" in logs

**Diagnosis**:
```bash
# Verify image exists in ACR
az acr repository show \
  --name fastapiregistry \
  --repository fastapi

# Check ACR credentials
az acr credential show --name fastapiregistry
```

**Solutions**:
```bash
# Update ACR credentials
ACR_USERNAME=$(az acr credential show --name fastapiregistry --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name fastapiregistry --query passwords[0].value --output tsv)

az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --registry-server fastapiregistry.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD
```

## Advanced: Application Insights

### Setup Application Insights

```bash
# Create Application Insights
az extension add --name application-insights

az monitor app-insights component create \
  --app fastapi-insights \
  --location eastus \
  --resource-group fastapi-rg \
  --application-type web

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app fastapi-insights \
  --resource-group fastapi-rg \
  --query instrumentationKey \
  --output tsv)

# Add to container app
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=$INSTRUMENTATION_KEY"
```

### View Application Insights

1. Go to Azure Portal
2. Navigate to: Resource Groups → `fastapi-rg` → `fastapi-insights`
3. Explore:
   - **Live Metrics**: Real-time telemetry
   - **Failures**: Exception tracking
   - **Performance**: Response time analysis
   - **Application Map**: Dependency visualization

## Alerts

### Create Alert for Errors

```bash
# Create action group (notification)
az monitor action-group create \
  --name fastapi-alerts \
  --resource-group fastapi-rg \
  --short-name fastapi \
  --email-receiver admin admin@example.com

# Create alert rule
az monitor metrics alert create \
  --name high-error-rate \
  --resource-group fastapi-rg \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/fastapi-rg/providers/Microsoft.App/containerApps/fastapi-app \
  --condition "avg Requests > 100" \
  --description "Alert when error rate is high" \
  --action fastapi-alerts
```

## Performance Optimization

### 1. Optimize Cold Starts

**Reduce image size**:
```dockerfile
# Use alpine base image
FROM python:3.12-alpine

# Install only production dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

**Pre-compile Python**:
```dockerfile
# Add to Dockerfile
RUN python -m compileall src/
```

### 2. Optimize Resource Usage

**Right-size your containers**:
```bash
# Start small
--cpu 0.25 --memory 0.5Gi  # Costs least

# Increase if needed
--cpu 0.5 --memory 1Gi     # Good for most apps

# For high-performance apps
--cpu 1.0 --memory 2Gi     # Costs more
```

### 3. Optimize Scaling

**Tune scaling parameters**:
```bash
az containerapp update \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --min-replicas 0 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-metadata concurrentRequests=50
```

## Useful CLI Commands

### Quick Status Check

```bash
# One-liner status check
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  --query "{Status:properties.provisioningState, URL:properties.configuration.ingress.fqdn, Replicas:properties.runningStatus}" \
  --output table
```

### Export Configuration

```bash
# Export current configuration
az containerapp show \
  --name fastapi-app \
  --resource-group fastapi-rg \
  > containerapp-config.json
```

### View All Resources

```bash
# List everything in resource group
az resource list \
  --resource-group fastapi-rg \
  --output table
```

## Cost Monitoring

### View Current Costs

```bash
# View consumption (requires billing access)
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --output table
```

### Cost Analysis in Portal

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to: **Cost Management + Billing**
3. Select: **Cost analysis**
4. Filter by: Resource Group = `fastapi-rg`

**💡 Set budget alerts** to avoid surprises!

## Best Practices

### 1. Structured Logging

Use JSON logging for better parsing:

```python
import logging
import json

# Configure JSON logging
logging.basicConfig(
    format='%(message)s',
    level=logging.INFO
)

# Log as JSON
logging.info(json.dumps({
    "event": "request_processed",
    "path": "/api/hello",
    "status": 200,
    "duration_ms": 45
}))
```

### 2. Health Checks

Implement proper health endpoints:

```python
@app.get("/api/health")
async def health():
    # Check dependencies
    try:
        # Check database connection, etc.
        return {"status": "healthy"}
    except Exception as e:
        raise HTTPException(status_code=503, detail="unhealthy")
```

### 3. Correlation IDs

Track requests across services:

```python
import uuid
from fastapi import Request

@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

## Summary

You now know how to:
- ✅ View logs (CLI and Portal)
- ✅ Monitor metrics and performance
- ✅ Debug common issues
- ✅ Set up Application Insights
- ✅ Create alerts
- ✅ Optimize performance and costs

## Next Steps

**[Tutorial 08: Cleanup](./08-cleanup.md)** - Remove resources to avoid charges

## Quick Reference

```bash
# Logs
az containerapp logs show --name fastapi-app --resource-group fastapi-rg --follow

# Replicas
az containerapp replica list --name fastapi-app --resource-group fastapi-rg

# Update app
az containerapp update --name fastapi-app --resource-group fastapi-rg

# View costs
az consumption usage list --output table
```
