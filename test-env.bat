@echo off
echo Testing Environment Variables...
echo ========================================

REM Load environment variables from .env file
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    if not "%%a"=="" if not "%%b"=="" set "%%a=%%b"
)

echo GOERLI_RPC_URL = %GOERLI_RPC_URL%
echo PRIVATE_KEY = %PRIVATE_KEY:~0,10%... (truncated for security)
echo ETH_TREASURY = %ETH_TREASURY%
echo ========================================
