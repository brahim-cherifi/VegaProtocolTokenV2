# ⚠️ WARNING: BSC MAINNET DEPLOYMENT - REAL FUNDS AT RISK!
# Make sure you have:
# 1. Enough BNB for gas (~0.1 BNB should be sufficient)
# 2. Tested on testnet first
# 3. Audited your contracts

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "⚠️  BSC MAINNET DEPLOYMENT WARNING  ⚠️" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "This will deploy to BSC MAINNET!" -ForegroundColor Red
Write-Host "Real funds will be used for gas!" -ForegroundColor Red
Write-Host "" 

# Load and set environment variables from .env file
$envFile = Get-Content ".env" -Raw
$envFile -split "`n" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        Write-Host "Set $name" -ForegroundColor Gray
    }
}

# Set BSC-specific environment variables
[System.Environment]::SetEnvironmentVariable("BSC_TREASURY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_STAKING_REWARDS", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_LIQUIDITY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_FEE_RECIPIENT", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSCSCAN_API_KEY", "8K2SN2YPQ3MRYEN74PEJJIGCVGSNJMM9XF", "Process")

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to BSC Mainnet" -ForegroundColor Green
Write-Host "Chain ID: 56" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# Get wallet address from private key
$walletAddress = "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6"
Write-Host "Deploying from wallet: $walletAddress" -ForegroundColor Cyan

# BSC Mainnet RPC URLs (multiple options for reliability)
$bscRpcUrls = @(
"https://mainnet.base.org"
)

# Use the first available RPC
$BSC_RPC_URL = $bscRpcUrls[0]
Write-Host "Using RPC: $BSC_RPC_URL" -ForegroundColor Cyan

# Deploy the contracts
Write-Host "Starting deployment..." -ForegroundColor Yellow
forge script script/Deploy.s.sol:DeployScript `
    --rpc-url $BSC_RPC_URL `
    --private-key "" `
    --broadcast `
    --chain-id 56 `
    --slow `
    --gas-price 3000000000 `
    --verify `
    --etherscan-api-key "8K2SN2YPQ3MRYEN74PEJJIGCVGSNJMM9XF" `
    -vvvv

if ($LASTEXITCODE -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ BSC MAINNET DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT POST-DEPLOYMENT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Verify contracts on BscScan" -ForegroundColor Cyan
    Write-Host "2. Add liquidity on PancakeSwap" -ForegroundColor Cyan
    Write-Host "3. Update AMM pairs in the contract" -ForegroundColor Cyan
    Write-Host "4. Transfer ownership to multisig" -ForegroundColor Cyan
    Write-Host "5. Announce deployment to community" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deployment failed. Check errors above." -ForegroundColor Red
}
