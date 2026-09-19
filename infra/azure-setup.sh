#!/usr/bin/env bash
# Day 2 · Homework (≈45 min) — build the Azure "house" the delivery truck will drive to on Day 3.
# Run in Azure Cloud Shell (Bash) or any shell with Azure CLI logged in (az login).
# Stays inside the Azure free account: 1 small Linux VM, 1 storage account, 1 app registration.
set -euo pipefail

# ---- 1. Fill these in -------------------------------------------------------
GITHUB_REPO="your-github-user/gha-mastery"     # owner/name, exactly as on GitHub
LOCATION="canadacentral"                        # pick a region where Standard_B2ats_v2 is offered
RG="rg-gha-mastery"
VM_NAME="vm-gha-linux"
VM_SIZE="Standard_B2ats_v2"                     # free-account size (Standard_B1s also works)
STORAGE_ACCOUNT="stghamastery$RANDOM"           # must be globally unique, lowercase, 3-24 chars
SSH_KEY="$HOME/.ssh/gha_deploy"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# ---- 2. SSH key the pipeline will use ------------------------------------------
[[ -f "$SSH_KEY" ]] || ssh-keygen -t ed25519 -N "" -C "github-actions-deploy" -f "$SSH_KEY"

# ---- 3. Resource group + Linux VM ---------------------------------------------
az group create -n "$RG" -l "$LOCATION" -o none

az vm create \
  -g "$RG" -n "$VM_NAME" \
  --image Ubuntu2404 \
  --size "$VM_SIZE" \
  --admin-username azureuser \
  --ssh-key-values "$SSH_KEY.pub" \
  --public-ip-sku Standard \
  --storage-sku Premium_LRS --os-disk-size-gb 64 \
  --nsg-rule NONE \
  -o none
# --nsg-rule NONE: no SSH open to the world. The pipeline opens 22 for its own IP, then closes it.

# The app ports (dev 8080, production 8081) are public so you can curl them from anywhere.
az vm open-port -g "$RG" -n "$VM_NAME" --port 8080-8081 --priority 1010 -o none

# Save money: shut the VM down every night at 04:00 UTC (midnight Toronto).
az vm auto-shutdown -g "$RG" -n "$VM_NAME" --time 0400 -o none

VM_IP=$(az vm show -d -g "$RG" -n "$VM_NAME" --query publicIps -o tsv)

# ---- 4. Storage account with a static website (WinForms download page) ----------
az storage account create -g "$RG" -n "$STORAGE_ACCOUNT" -l "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 -o none
az storage blob service-properties update --account-name "$STORAGE_ACCOUNT" \
  --static-website --index-document index.html --auth-mode login -o none
SITE_URL=$(az storage account show -g "$RG" -n "$STORAGE_ACCOUNT" --query primaryEndpoints.web -o tsv)

# ---- 5. Identity for GitHub Actions (OIDC, no client secret) --------------------
APP_ID=$(az ad app create --display-name "github-actions-gha-mastery" --query appId -o tsv)
SP_OBJECT_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)

RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG"
# Least privilege: only this resource group, not the whole subscription.
az role assignment create --assignee-object-id "$SP_OBJECT_ID" --assignee-principal-type ServicePrincipal \
  --role "Network Contributor" --scope "$RG_SCOPE" -o none
az role assignment create --assignee-object-id "$SP_OBJECT_ID" --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" --scope "$RG_SCOPE/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" -o none
# Lets *you* upload from the CLI too (useful for debugging the download site).
az role assignment create --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Storage Blob Data Contributor" --scope "$RG_SCOPE/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" -o none || true

# One federated credential per "who is allowed to ask for a token".
for SUBJECT in "environment:dev" "environment:production" "ref:refs/heads/main"; do
  NAME=$(echo "$SUBJECT" | tr ':/' '--')
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"gh-$NAME\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_REPO:$SUBJECT\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" -o none
done

# ---- 6. What to paste into GitHub ---------------------------------------------
cat <<OUT

=====================  Paste into GitHub  =====================
Settings > Secrets and variables > Actions > *Secrets*
  AZURE_CLIENT_ID        = $APP_ID
  AZURE_TENANT_ID        = $TENANT_ID
  AZURE_SUBSCRIPTION_ID  = $SUBSCRIPTION_ID
  SSH_PRIVATE_KEY        = (contents of $SSH_KEY  — the file WITHOUT .pub)

Settings > Secrets and variables > Actions > *Variables*
  AZURE_RG               = $RG
  VM_NAME                = $VM_NAME
  VM_HOST                = $VM_IP
  STORAGE_ACCOUNT        = $STORAGE_ACCOUNT
  DOWNLOAD_SITE_URL      = $SITE_URL

Settings > Environments
  dev          -> variables APP_NAME=contract-api-dev   APP_PORT=8080
  production   -> variables APP_NAME=contract-api-prod  APP_PORT=8081
                  + Required reviewers: you  (+ Deployment branches: main)
================================================================
OUT
