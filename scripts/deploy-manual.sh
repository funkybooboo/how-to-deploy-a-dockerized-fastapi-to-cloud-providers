#!/bin/bash
# Manually deploy FastAPI application to Azure Container Apps
#
# This script builds a Docker image, pushes it to Azure Container Registry,
# and deploys it to Azure Container Apps with production configuration.
#
# Prerequisites:
#   - Run ./scripts/setup-azure.sh first
#   - Docker must be running
#   - Authenticated with Azure CLI
#
# Usage: ./scripts/deploy-manual.sh [version-tag]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying FastAPI to Azure Container Apps${NC}\n"

# Load configuration if it exists
if [ -f .azure-config ]; then
    source .azure-config
    echo -e "${GREEN}✅ Loaded configuration from .azure-config${NC}"
else
    echo -e "${YELLOW}⚠️  No .azure-config found. Using defaults or prompting...${NC}"
    RESOURCE_GROUP="fastapi-rg"
    LOCATION="eastus"
    ACR_NAME=""
    CONTAINER_APP_ENV="fastapi-env"
fi

# Check if ACR_NAME is set
if [ -z "$ACR_NAME" ]; then
    echo -e "${RED}❌ ACR_NAME not found in configuration${NC}"
    echo -e "${YELLOW}Please run ./scripts/setup-azure.sh first${NC}"
    exit 1
fi

# Set defaults
CONTAINER_APP_NAME="fastapi-app"
VERSION=${1:-"latest"}

# Get ACR details
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer --output tsv 2>/dev/null)

if [ -z "$ACR_LOGIN_SERVER" ]; then
    echo -e "${RED}❌ Could not find ACR '${ACR_NAME}'${NC}"
    echo -e "${YELLOW}Please run ./scripts/setup-azure.sh first${NC}"
    exit 1
fi

# Construct image name
IMAGE="${ACR_LOGIN_SERVER}/fastapi:${VERSION}"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Resource Group:  ${RESOURCE_GROUP}"
echo -e "  Location:        ${LOCATION}"
echo -e "  ACR Name:        ${ACR_NAME}"
echo -e "  Container App:   ${CONTAINER_APP_NAME}"
echo -e "  Image:           ${IMAGE}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo -e "${YELLOW}Please start Docker and try again${NC}"
    exit 1
fi

# Login to ACR
echo -e "${GREEN}🔐 Logging in to Azure Container Registry...${NC}"
az acr login --name "$ACR_NAME"

# Build Docker image
echo -e "\n${GREEN}🏗️  Building Docker image...${NC}"
docker build -f Dockerfile.prod -t "$IMAGE" .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Also tag as latest if a specific version was provided
if [ "$VERSION" != "latest" ]; then
    LATEST_IMAGE="${ACR_LOGIN_SERVER}/fastapi:latest"
    docker tag "$IMAGE" "$LATEST_IMAGE"
    echo -e "${GREEN}✅ Tagged as latest${NC}"
fi

# Push to Azure Container Registry
echo -e "\n${GREEN}📤 Pushing image to Azure Container Registry...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"

docker push "$IMAGE"

if [ "$VERSION" != "latest" ]; then
    docker push "$LATEST_IMAGE"
fi

echo -e "${GREEN}✅ Image pushed successfully${NC}"

# Get ACR credentials
echo -e "\n${GREEN}🔑 Retrieving ACR credentials...${NC}"
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value --output tsv)

# Check if container app exists
echo -e "\n${GREEN}📋 Checking if container app exists...${NC}"
APP_EXISTS=$(az containerapp show --name "$CONTAINER_APP_NAME" --resource-group "$RESOURCE_GROUP" 2>/dev/null || echo "")

if [ -z "$APP_EXISTS" ]; then
    # Create new container app
    echo -e "${GREEN}🚀 Creating new container app...${NC}"

    az containerapp create \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --environment "$CONTAINER_APP_ENV" \
        --image "$IMAGE" \
        --registry-server "$ACR_LOGIN_SERVER" \
        --registry-username "$ACR_USERNAME" \
        --registry-password "$ACR_PASSWORD" \
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

    echo -e "${GREEN}✅ Container app created successfully!${NC}"
else
    # Update existing container app
    echo -e "${GREEN}🔄 Updating existing container app...${NC}"

    az containerapp update \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --image "$IMAGE"

    echo -e "${GREEN}✅ Container app updated successfully!${NC}"
fi

# Get service URL
echo -e "\n${GREEN}🌐 Getting service URL...${NC}"
FQDN=$(az containerapp show \
    --name "$CONTAINER_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.configuration.ingress.fqdn \
    --output tsv)

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "\n${GREEN}Service URL:${NC} ${YELLOW}https://${FQDN}${NC}\n"
echo -e "${GREEN}Test endpoints:${NC}"
echo -e "  Root:    ${YELLOW}https://${FQDN}/${NC}"
echo -e "  Health:  ${YELLOW}https://${FQDN}/api/health${NC}"
echo -e "  Hello:   ${YELLOW}https://${FQDN}/api/hello${NC}"
echo -e "  Docs:    ${YELLOW}https://${FQDN}/api/docs${NC}"
echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Test the deployment
echo -e "${GREEN}🧪 Testing deployment...${NC}"
echo -e "${YELLOW}Waiting for service to be ready...${NC}"
sleep 10  # Wait for service to be fully ready

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${FQDN}/")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Service is responding correctly!${NC}\n"
else
    echo -e "${YELLOW}⚠️  Service returned HTTP ${HTTP_CODE}${NC}"
    echo -e "${YELLOW}Check logs: az containerapp logs show --name ${CONTAINER_APP_NAME} --resource-group ${RESOURCE_GROUP} --follow${NC}\n"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Useful commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "  View logs:"
echo -e "    ${YELLOW}az containerapp logs show --name ${CONTAINER_APP_NAME} --resource-group ${RESOURCE_GROUP} --follow${NC}"
echo -e ""
echo -e "  List replicas:"
echo -e "    ${YELLOW}az containerapp replica list --name ${CONTAINER_APP_NAME} --resource-group ${RESOURCE_GROUP}${NC}"
echo -e ""
echo -e "  Update app:"
echo -e "    ${YELLOW}az containerapp update --name ${CONTAINER_APP_NAME} --resource-group ${RESOURCE_GROUP}${NC}"
echo -e ""
echo -e "  Delete app:"
echo -e "    ${YELLOW}./scripts/cleanup.sh${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
