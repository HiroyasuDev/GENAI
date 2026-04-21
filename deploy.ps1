# OpenCode AI Lab — One-Click Deploy Script (PowerShell)
# ======================================================
# Usage:
#   .\deploy.ps1 -ProjectId "your-gcp-project-id"
#
# Prerequisites:
#   - Terraform installed (https://developer.hashicorp.com/terraform/install)
#   - gcloud CLI authenticated (gcloud auth application-default login)
#   - GCP project with Compute Engine API enabled

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,

    [string]$Region = "us-central1",
    [string]$Zone = "us-central1-a",
    [string]$MachineType = "e2-standard-4"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenCode AI Lab — One-Click Deploy"    -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to terraform directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$terraformDir = Join-Path $scriptDir "terraform"
Push-Location $terraformDir

try {
    # Write terraform.tfvars
    @"
project_id   = "$ProjectId"
region       = "$Region"
zone         = "$Zone"
machine_type = "$MachineType"
"@ | Out-File -FilePath "terraform.tfvars" -Encoding utf8

    Write-Host "[1/4] Initializing Terraform..." -ForegroundColor Yellow
    terraform init -input=false

    Write-Host "[2/4] Planning infrastructure..." -ForegroundColor Yellow
    terraform plan -out=tfplan

    Write-Host "[3/4] Deploying VM + firewall rules..." -ForegroundColor Yellow
    terraform apply -auto-approve tfplan

    Write-Host ""
    Write-Host "[4/4] Retrieving outputs..." -ForegroundColor Yellow
    $labUrl = terraform output -raw lab_url
    $externalIp = terraform output -raw vm_external_ip
    $sshCmd = terraform output -raw ssh_command

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Web Terminal:  $labUrl" -ForegroundColor White
    Write-Host "  SSH:           $sshCmd" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  The startup script is installing dependencies" -ForegroundColor Yellow
    Write-Host "  and downloading the model (~5-8 minutes)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Monitor progress:" -ForegroundColor DarkGray
    Write-Host "    $sshCmd -- tail -f /var/log/opencode-lab-startup.log" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  To update GitHub Pages with the new IP:" -ForegroundColor DarkGray
    Write-Host "    Replace the href in docs/index.html with:" -ForegroundColor DarkGray
    Write-Host "    http://${externalIp}:7681" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  To destroy:" -ForegroundColor Red
    Write-Host "    terraform destroy -auto-approve" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Green

    # Remove plan file
    Remove-Item -Force tfplan -ErrorAction SilentlyContinue
}
finally {
    Pop-Location
}
