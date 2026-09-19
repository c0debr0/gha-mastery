#!/usr/bin/env bash
# End of course — delete everything so nothing keeps billing after the free period.
set -euo pipefail
RG="rg-gha-mastery"
az group delete -n "$RG" --yes --no-wait
APP_ID=$(az ad app list --display-name "github-actions-gha-mastery" --query "[0].appId" -o tsv)
[[ -n "$APP_ID" ]] && az ad app delete --id "$APP_ID"
echo "Deleting $RG in the background. Check the portal in ~5 minutes."
