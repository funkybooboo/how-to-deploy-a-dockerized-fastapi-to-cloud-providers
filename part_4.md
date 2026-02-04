# Part 4

## Follow along

1. `mkdir -p .github/workflows`
2. `touch .github/workflows/cicd.yaml`
3. Set up Azure credentials in GitHub Secrets:
   - Create a service principal: `az ad sp create-for-rbac --name fastapi-github-actions --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/fastapi-rg --sdk-auth`
   - Add the output JSON as `AZURE_CREDENTIALS` secret in GitHub
   - Add your ACR credentials as `ACR_USERNAME` and `ACR_PASSWORD` secrets
4. Configure the workflow to deploy on push to `azure` branch
5. Push to your `azure` branch to trigger deployment
6. View the status of the action in real-time on the Actions tab

## Reference links

- https://learn.microsoft.com/en-us/azure/container-apps/github-actions
- https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure
- https://docs.github.com/en/actions/deployment/deploying-to-azure

## Troubleshooting

If you run into permissions issues with your Azure Service Principal, you may need to assign additional roles:

```sh
# Grant ACR push permission
az role assignment create --assignee <service-principal-app-id> \
    --role AcrPush \
    --scope /subscriptions/{subscription-id}/resourceGroups/fastapi-rg/providers/Microsoft.ContainerRegistry/registries/fastapiregistry

# Grant Container Apps contributor role
az role assignment create --assignee <service-principal-app-id> \
    --role "Contributor" \
    --scope /subscriptions/{subscription-id}/resourceGroups/fastapi-rg
```
