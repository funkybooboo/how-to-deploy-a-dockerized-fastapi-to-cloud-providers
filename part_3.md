# Part 3

## Follow along

1. Install Azure CLI in your dev container (optional - can be added to Dockerfile.dev)
   - `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`
2. SMOKE TEST the Azure CLI
   - `az --version`
3. Login to Azure
   - `az login`
4. Create a resource group
   - `az group create --name fastapi-rg --location eastus`
5. Create an Azure Container Registry (ACR)
   - `az acr create --resource-group fastapi-rg --name fastapiregistry --sku Basic`
6. Login to ACR
   - `az acr login --name fastapiregistry`
7. Build and push Docker image to ACR
   - `docker build -f Dockerfile.prod -t fastapiregistry.azurecr.io/fastapi:latest .`
   - `docker push fastapiregistry.azurecr.io/fastapi:latest`
8. Create Azure Container Apps environment
   - `az containerapp env create --name fastapi-env --resource-group fastapi-rg --location eastus`
9. Create `azure-container-app.yaml` configuration file
10. Deploy to Azure Container Apps
    - `az containerapp create --name fastapi-app --resource-group fastapi-rg --environment fastapi-env --image fastapiregistry.azurecr.io/fastapi:latest --target-port 8080 --ingress external --registry-server fastapiregistry.azurecr.io`
11. Get the application URL
    - `az containerapp show --name fastapi-app --resource-group fastapi-rg --query properties.configuration.ingress.fqdn`

## Reference links

- https://fastapi.tiangolo.com/
- https://learn.microsoft.com/en-us/azure/container-apps/
- https://learn.microsoft.com/en-us/azure/container-registry/
- https://learn.microsoft.com/en-us/cli/azure/
