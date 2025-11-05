# PowerShell deployment script for testnet
# Load .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

# Display loaded values
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to Sepolia Testnet" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green

# Use Sepolia instead of deprecated Goerli
$RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/eXjXRqzZhOg70zvNYg-sR"
$PRIVATE_KEY = $env:PRIVATE_KEY

if (-not $PRIVATE_KEY) {
    Write-Host "ERROR: PRIVATE_KEY not found in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "RPC URL: $RPC_URL" -ForegroundColor Yellow
Write-Host "Deploying contracts..." -ForegroundColor Yellow

# Deploy to Sepolia (chainId 11155111)
forge script script/Deploy.s.sol:DeployScript `
    --rpc-url $RPC_URL `
    --private-key $PRIVATE_KEY `
    --broadcast `
    --chain-id 11155111 `
    -vvvv

Write-Host "Deployment completed!" -ForegroundColor Green
