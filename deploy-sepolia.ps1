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

# Additional environment variables that might be missing
[System.Environment]::SetEnvironmentVariable("BASESCAN_API_KEY", "8K2SN2YPQ3MRYEN74PEJJIGCVGSNJMM9XF", "Process")
[System.Environment]::SetEnvironmentVariable("ETH_TREASURY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("ETH_STAKING_REWARDS", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("ETH_LIQUIDITY", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")
[System.Environment]::SetEnvironmentVariable("ETH_FEE_RECIPIENT", "0x232a3f981F3347a9DCCd446c81CEc1d6B120AAF6", "Process")

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to Sepolia Testnet" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Now run the deployment
forge script script/Deploy.s.sol:DeployScript `
    --rpc-url "https://eth-sepolia.g.alchemy.com/v2/eXjXRqzZhOg70zvNYg-sR" `
    --private-key "0f556f4cbbd1805c1d099d7f135c3eca930e38a69f0d751b3cb7938ab43b6e0b" `
    --broadcast `
    --chain-id 11155111 `
    -vvvv

Write-Host "Deployment completed!" -ForegroundColor Green
