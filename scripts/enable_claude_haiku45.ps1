<#
Enable Claude Haiku 4.5 for all clients (generic automation template)

This script is a template. Most vendors have different admin APIs —
update the $Endpoint and request body as needed for your vendor.

Usage examples:
  .\enable_claude_haiku45.ps1 -ApiUrl "https://api.vendor.example" -ApiKey "<ADMIN_KEY>" -ModelName "claude-haiku-4.5" -DryRun
  # or interactively run and paste the ApiKey when prompted

IMPORTANT: This script does not know your vendor's exact API shape.
Read and adapt the comments below before running in production.
#>
param(
    [Parameter(Mandatory=$false)] [string]$ApiUrl,
    [Parameter(Mandatory=$false)] [string]$ApiKey,
    [Parameter(Mandatory=$false)] [string]$ModelName = "claude-haiku-4.5",
    [switch]$DryRun
)

function Prompt-ForSecrets {
    if (-not $ApiUrl) {
        $ApiUrl = Read-Host -Prompt "Enter admin API base URL (e.g. https://admin.vendor.example)"
    }
    if (-not $ApiKey) {
        $secure = Read-Host -Prompt "Enter admin API key (will not echo)" -AsSecureString
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
}

Prompt-ForSecrets

Write-Host "Target API URL: $ApiUrl"
Write-Host "Model to enable: $ModelName"
if ($DryRun) { Write-Host "DRY RUN: No changes will be sent." }

# ------------------------------------------------------------------
# Vendor-specific instructions (pick one and adapt):
# 1) Example: Feature-flag / config endpoint (common for internal proxies)
#    - Endpoint: PATCH/PUT to /config/feature-flags or /models
#    - Body example: { "enabled_models": [ "claude-haiku-4.5" ] }
# 2) Example: Admin model toggle API
#    - Endpoint: POST /admin/models/{model}/enable or PATCH /admin/models/{model}
#    - Body example: { "enable_for_all": true }
# ------------------------------------------------------------------

# PICK the right endpoint and body for your vendor. Below are two examples.

# --- Example A: generic feature-flag style (JSON body) ---
$exampleAEndpoint = "$ApiUrl/api/v1/config"    # <-- CHANGE this
$exampleABody = @{ enabled_models = @($ModelName) } | ConvertTo-Json -Depth 5

# --- Example B: admin-model-toggle (per-model endpoint) ---
$exampleBEndpoint = "$ApiUrl/api/v1/admin/models/$ModelName/enable"  # <-- CHANGE this
$exampleBBody = @{ enable_for_all = $true } | ConvertTo-Json -Depth 5

# Decide which example to use by setting $Endpoint and $Body accordingly.
# By default we will try Example B if the URL path appears valid, otherwise A.
$Endpoint = $null; $Body = $null
if ($ApiUrl -match "/admin/|/models/") {
    $Endpoint = $exampleBEndpoint
    $Body = $exampleBBody
} else {
    $Endpoint = $exampleAEndpoint
    $Body = $exampleABody
}

Write-Host "Using endpoint: $Endpoint"
Write-Host "Request body:`n$Body"

if ($DryRun) { exit 0 }

# Prepare headers
$headers = @{ "Authorization" = "Bearer $ApiKey"; "Content-Type" = "application/json" }

try {
    # Try PATCH first (commonly used for config updates), fallback to POST
    Write-Host "Attempting PATCH $Endpoint ..."
    $response = Invoke-RestMethod -Method Patch -Uri $Endpoint -Headers $headers -Body $Body -ErrorAction Stop
    Write-Host "PATCH response:`n" ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Warning "PATCH failed: $($_.Exception.Message) -- trying POST as fallback"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $Body -ErrorAction Stop
        Write-Host "POST response:`n" ($response | ConvertTo-Json -Depth 5)
    } catch {
        Write-Error "Both PATCH and POST attempts failed. Last error: $($_.Exception.Message)"
        Write-Host "Please adapt the script's endpoint and payload to match your vendor admin API."
        exit 2
    }
}

Write-Host "Operation completed. Verify in the admin console or by running a smoke test request using a client key."
exit 0
