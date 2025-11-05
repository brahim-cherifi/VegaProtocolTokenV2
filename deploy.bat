@echo off
REM Vega Token Multi-Chain Deployment Script for Windows
REM Usage: deploy.bat [network] [action]
REM Networks: eth, bsc, base, eth-testnet, bsc-testnet, base-testnet, local
REM Actions: deploy, verify, both

setlocal enabledelayedexpansion

set NETWORK=%1
if "%2"=="" (set ACTION=deploy) else (set ACTION=%2)

echo ========================================
echo Vega Token Deployment Script
echo ========================================

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found!
    echo Please create a .env file with your configuration
    exit /b 1
)

REM Load environment variables from .env file
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    if not "%%a"=="" if not "%%b"=="" set "%%a=%%b"
)

if "%NETWORK%"=="eth" (
    if "%ACTION%"=="deploy" goto :deploy_eth
    if "%ACTION%"=="verify" goto :verify_eth
    if "%ACTION%"=="both" (
        call :deploy_eth
        call :verify_eth
    )
    goto :end
)

if "%NETWORK%"=="bsc" (
    if "%ACTION%"=="deploy" goto :deploy_bsc
    if "%ACTION%"=="verify" goto :verify_bsc
    if "%ACTION%"=="both" (
        call :deploy_bsc
        call :verify_bsc
    )
    goto :end
)

if "%NETWORK%"=="base" (
    if "%ACTION%"=="deploy" goto :deploy_base
    if "%ACTION%"=="verify" goto :verify_base
    if "%ACTION%"=="both" (
        call :deploy_base
        call :verify_base
    )
    goto :end
)

if "%NETWORK%"=="eth-testnet" (
    if "%ACTION%"=="deploy" goto :deploy_eth_testnet
    if "%ACTION%"=="verify" goto :verify_eth_testnet
    if "%ACTION%"=="both" (
        call :deploy_eth_testnet
        call :verify_eth_testnet
    )
    goto :end
)

if "%NETWORK%"=="bsc-testnet" (
    if "%ACTION%"=="deploy" goto :deploy_bsc_testnet
    if "%ACTION%"=="verify" goto :verify_bsc_testnet
    if "%ACTION%"=="both" (
        call :deploy_bsc_testnet
        call :verify_bsc_testnet
    )
    goto :end
)

if "%NETWORK%"=="base-testnet" (
    if "%ACTION%"=="deploy" goto :deploy_base_testnet
    if "%ACTION%"=="verify" goto :verify_base_testnet
    if "%ACTION%"=="both" (
        call :deploy_base_testnet
        call :verify_base_testnet
    )
    goto :end
)

if "%NETWORK%"=="local" (
    echo Starting local node...
    start /b anvil --fork-url %ETH_RPC_URL%
    timeout /t 5
    call :deploy_local
    echo Stopping local node...
    taskkill /f /im anvil.exe
    goto :end
)

if "%NETWORK%"=="all-mainnet" (
    echo Deploying to all mainnet chains...
    call deploy.bat eth %ACTION%
    call deploy.bat bsc %ACTION%
    call deploy.bat base %ACTION%
    echo All mainnet deployments completed!
    goto :end
)

if "%NETWORK%"=="all-testnet" (
    echo Deploying to all testnet chains...
    call deploy.bat eth-testnet %ACTION%
    call deploy.bat bsc-testnet %ACTION%
    call deploy.bat base-testnet %ACTION%
    echo All testnet deployments completed!
    goto :end
)

echo Error: Invalid network specified
echo Usage: deploy.bat [network] [action]
echo Networks: eth, bsc, base, eth-testnet, bsc-testnet, base-testnet, local, all-mainnet, all-testnet
echo Actions: deploy, verify, both
exit /b 1

:deploy_eth
echo Deploying to Ethereum Mainnet...
forge script script/Deploy.s.sol:DeployScript --rpc-url %ETH_RPC_URL% --broadcast --verify --chain-id 1 -vvvv
echo Deployment to Ethereum Mainnet completed!
exit /b 0

:verify_eth
echo Verifying contracts on Ethereum Mainnet...
forge script script/Verify.s.sol:VerifyScript --chain-id 1 -vvvv
echo Verification on Ethereum Mainnet completed!
exit /b 0

:deploy_bsc
echo Deploying to BSC Mainnet...
forge script script/Deploy.s.sol:DeployScript --rpc-url %BSC_RPC_URL% --broadcast --verify --chain-id 56 -vvvv
echo Deployment to BSC Mainnet completed!
exit /b 0

:verify_bsc
echo Verifying contracts on BSC Mainnet...
forge script script/Verify.s.sol:VerifyScript --chain-id 56 -vvvv
echo Verification on BSC Mainnet completed!
exit /b 0

:deploy_base
echo Deploying to Base Mainnet...
forge script script/Deploy.s.sol:DeployScript --rpc-url %BASE_RPC_URL% --broadcast --verify --chain-id 8453 -vvvv
echo Deployment to Base Mainnet completed!
exit /b 0

:verify_base
echo Verifying contracts on Base Mainnet...
forge script script/Verify.s.sol:VerifyScript --chain-id 8453 -vvvv
echo Verification on Base Mainnet completed!
exit /b 0

:deploy_eth_testnet
echo Deploying to Goerli Testnet...
forge script script/Deploy.s.sol:DeployScript --rpc-url %GOERLI_RPC_URL% --broadcast --verify --chain-id 5 -vvvv
echo Deployment to Goerli Testnet completed!
exit /b 0

:verify_eth_testnet
echo Verifying contracts on Goerli Testnet...
forge script script/Verify.s.sol:VerifyScript --chain-id 5 -vvvv
echo Verification on Goerli Testnet completed!
exit /b 0

:deploy_bsc_testnet
echo Deploying to BSC Testnet...
forge script script/Deploy.s.sol:DeployScript --rpc-url %BSC_TESTNET_RPC_URL% --broadcast --verify --chain-id 97 -vvvv
echo Deployment to BSC Testnet completed!
exit /b 0

:verify_bsc_testnet
echo Verifying contracts on BSC Testnet...
forge script script/Verify.s.sol:VerifyScript --chain-id 97 -vvvv
echo Verification on BSC Testnet completed!
exit /b 0

:deploy_base_testnet
echo Deploying to Base Goerli...
forge script script/Deploy.s.sol:DeployScript --rpc-url %BASE_GOERLI_RPC_URL% --broadcast --verify --chain-id 84531 -vvvv
echo Deployment to Base Goerli completed!
exit /b 0

:verify_base_testnet
echo Verifying contracts on Base Goerli...
forge script script/Verify.s.sol:VerifyScript --chain-id 84531 -vvvv
echo Verification on Base Goerli completed!
exit /b 0

:deploy_local
echo Deploying to Local Network...
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast --chain-id 31337 -vvvv
echo Deployment to Local Network completed!
exit /b 0

:end
echo ========================================
echo Script execution completed!
echo ========================================
