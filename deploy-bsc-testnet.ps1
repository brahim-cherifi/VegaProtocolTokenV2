# BSC Testnet Deployment Script (Safe Testing Environment)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to BSC Testnet" -ForegroundColor Green
Write-Host "Chain ID: 97" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# Set ALL required environment variables explicitly
[System.Environment]::SetEnvironmentVariable("PRIVATE_KEY", "0x0f556f4cbbd1805c1d099d7f135c3eca930e38a69f0d751b3cb7938ab43b6e0b", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_TREASURY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_STAKING_REWARDS", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_LIQUIDITY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSC_FEE_RECIPIENT", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("BSCSCAN_API_KEY", "8K2SN2YPQ3MRYEN74PEJJIGCVGSNJMM9XF", "Process")

Write-Host "Environment variables set" -ForegroundColor Gray

# BSC Testnet RPC
$BSC_TESTNET_RPC = "https://data-seed-prebsc-1-s1.binance.org:8545"

Write-Host "Using RPC: $BSC_TESTNET_RPC" -ForegroundColor Cyan
Write-Host "Get testnet BNB from: https://testnet.bnbchain.org/faucet-smart" -ForegroundColor Yellow

# Deploy
forge script script/Deploy.s.sol:DeployScript `
    --rpc-url $BSC_TESTNET_RPC `
    --private-key "0x0f556f4cbbd1805c1d099d7f135c3eca930e38a69f0d751b3cb7938ab43b6e0b" `
    --broadcast `
    --chain-id 97 `
    --verify `
    --etherscan-api-key "8K2SN2YPQ3MRYEN74PEJJIGCVGSNJMM9XF" `
    -vvvv

Write-Host "BSC Testnet deployment completed!" -ForegroundColor Green
Write-Host "View on BscScan Testnet: https://testnet.bscscan.com/" -ForegroundColor Cyan
