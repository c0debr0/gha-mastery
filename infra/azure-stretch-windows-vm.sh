#!/usr/bin/env bash
# Day 3 · Stretch — a small Windows Server VM that Ansible manages over SSH.
# Windows on 1 GiB RAM is slow. Create it, do the lab, then run azure-teardown.sh or delete just this VM.
set -euo pipefail
RG="rg-gha-mastery"
WIN_VM_NAME="vm-gha-win"
SSH_KEY="$HOME/.ssh/gha_deploy"
ADMIN_PASSWORD="${ADMIN_PASSWORD:?export ADMIN_PASSWORD first (12+ chars, upper/lower/digit/symbol)}"

az vm create -g "$RG" -n "$WIN_VM_NAME" \
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-core-smalldisk:latest \
  --size Standard_B2ats_v2 \
  --admin-username azureuser --admin-password "$ADMIN_PASSWORD" \
  --public-ip-sku Standard --nsg-rule NONE -o none

az vm auto-shutdown -g "$RG" -n "$WIN_VM_NAME" --time 0400 -o none

# Install OpenSSH Server, make PowerShell the default shell, trust the pipeline's key.
PUBKEY=$(cat "$SSH_KEY.pub")
az vm run-command invoke -g "$RG" -n "$WIN_VM_NAME" --command-id RunPowerShellScript --scripts "
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  Set-Service -Name sshd -StartupType Automatic
  Start-Service sshd
  New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force
  Set-Content -Path 'C:\ProgramData\ssh\administrators_authorized_keys' -Value '$PUBKEY'
  icacls.exe 'C:\ProgramData\ssh\administrators_authorized_keys' /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F'
  Restart-Service sshd
" -o none

echo "Add GitHub variables: WIN_VM_NAME=$WIN_VM_NAME  WIN_VM_HOST=$(az vm show -d -g "$RG" -n "$WIN_VM_NAME" --query publicIps -o tsv)"
