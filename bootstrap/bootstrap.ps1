<#
 One-time bootstrap for CI/CD Lab 1 (run in PowerShell after 'az login').
 Creates: Terraform state storage, Entra app with GitHub OIDC federation, role assignments.
 Usage:  .\bootstrap\bootstrap.ps1 -GitHubUser yourname -GitHubRepo cicd-lab1
#>
param(
  [Parameter(Mandatory = $true)] [string] $GitHubUser,
  [string] $GitHubRepo = "cicd-lab1",
  [string] $Location   = "centralindia",
  [string] $StateRg    = "rg-tfstate-lab"
)

$ErrorActionPreference = "Stop"

$subId    = az account show --query id -o tsv
$tenantId = az account show --query tenantId -o tsv
$stateSa  = "sttfstate$(Get-Random -Minimum 10000 -Maximum 99999)lab"

Write-Host "Creating state storage $stateSa in $StateRg ..."
az group create -n $StateRg -l $Location | Out-Null
az storage account create -n $stateSa -g $StateRg -l $Location `
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false | Out-Null
az storage container create -n tfstate --account-name $stateSa --auth-mode key | Out-Null

Write-Host "Creating Entra app registration ..."
$appId = az ad app create --display-name "sp-github-cicd-lab1" --query appId -o tsv
az ad sp create --id $appId | Out-Null

$credentials = @(
  @{ name = "gh-pull-request";   subject = "repo:${GitHubUser}/${GitHubRepo}:pull_request" },
  @{ name = "gh-env-production"; subject = "repo:${GitHubUser}/${GitHubRepo}:environment:production" }
)
foreach ($c in $credentials) {
  $json = @{
    name      = $c.name
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = $c.subject
    audiences = @("api://AzureADTokenExchange")
  } | ConvertTo-Json
  $file = Join-Path $env:TEMP "$($c.name).json"
  $json | Set-Content -Path $file
  az ad app federated-credential create --id $appId --parameters $file | Out-Null
  Remove-Item $file
}

Write-Host "Assigning roles (subscription scope, lab only) ..."
az role assignment create --assignee $appId --role "Contributor" --scope "/subscriptions/$subId" | Out-Null
az role assignment create --assignee $appId --role "Storage Blob Data Contributor" --scope "/subscriptions/$subId" | Out-Null

Write-Host ""
Write-Host "Add these as GitHub repository VARIABLES (Settings > Secrets and variables > Actions > Variables):"
Write-Host "  AZURE_CLIENT_ID       = $appId"
Write-Host "  AZURE_TENANT_ID       = $tenantId"
Write-Host "  AZURE_SUBSCRIPTION_ID = $subId"
Write-Host "  TFSTATE_RG            = $StateRg"
Write-Host "  TFSTATE_SA            = $stateSa"
Write-Host ""
Write-Host "Then create a GitHub Environment named 'production' with yourself as Required reviewer."
Write-Host "Role assignments can take up to 5 minutes to propagate."
