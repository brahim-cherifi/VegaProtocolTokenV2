#!/bin/bash

# Vega Token Multi-Chain Deployment Script
# Usage: ./deploy.sh [network] [action]
# Networks: eth, bsc, base, eth-testnet, bsc-testnet, base-testnet, local
# Actions: deploy, verify, both

set -e

NETWORK=$1
ACTION=${2:-deploy}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Vega Token Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create a .env file with your configuration"
    exit 1
fi

# Load environment variables
source .env

# Function to deploy contracts
deploy_contracts() {
    local CHAIN_NAME=$1
    local RPC_URL=$2
    local CHAIN_ID=$3
    
    echo -e "${YELLOW}Deploying to $CHAIN_NAME...${NC}"
    echo "Chain ID: $CHAIN_ID"
    echo "RPC URL: $RPC_URL"
    
    forge script script/Deploy.s.sol:DeployScript \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        --chain-id $CHAIN_ID \
        -vvvv
    
    echo -e "${GREEN}Deployment to $CHAIN_NAME completed!${NC}"
}

# Function to verify contracts
verify_contracts() {
    local CHAIN_NAME=$1
    local CHAIN_ID=$2
    
    echo -e "${YELLOW}Verifying contracts on $CHAIN_NAME...${NC}"
    
    forge script script/Verify.s.sol:VerifyScript \
        --chain-id $CHAIN_ID \
        -vvvv
    
    echo -e "${GREEN}Verification on $CHAIN_NAME completed!${NC}"
}

# Main deployment logic
case $NETWORK in
    eth)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "Ethereum Mainnet" "$ETH_RPC_URL" 1
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "Ethereum Mainnet" 1
        fi
        ;;
    bsc)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "BSC Mainnet" "$BSC_RPC_URL" 56
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "BSC Mainnet" 56
        fi
        ;;
    base)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "Base Mainnet" "$BASE_RPC_URL" 8453
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "Base Mainnet" 8453
        fi
        ;;
    eth-testnet)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "Goerli Testnet" "$GOERLI_RPC_URL" 5
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "Goerli Testnet" 5
        fi
        ;;
    bsc-testnet)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "BSC Testnet" "$BSC_TESTNET_RPC_URL" 97
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "BSC Testnet" 97
        fi
        ;;
    base-testnet)
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "Base Goerli" "$BASE_GOERLI_RPC_URL" 84531
        fi
        if [ "$ACTION" = "verify" ] || [ "$ACTION" = "both" ]; then
            verify_contracts "Base Goerli" 84531
        fi
        ;;
    local)
        echo -e "${YELLOW}Starting local node...${NC}"
        anvil --fork-url $ETH_RPC_URL &
        ANVIL_PID=$!
        sleep 5
        
        if [ "$ACTION" = "deploy" ] || [ "$ACTION" = "both" ]; then
            deploy_contracts "Local Network" "http://localhost:8545" 31337
        fi
        
        echo -e "${YELLOW}Stopping local node...${NC}"
        kill $ANVIL_PID
        ;;
    all-mainnet)
        echo -e "${YELLOW}Deploying to all mainnet chains...${NC}"
        ./deploy.sh eth $ACTION
        ./deploy.sh bsc $ACTION
        ./deploy.sh base $ACTION
        echo -e "${GREEN}All mainnet deployments completed!${NC}"
        ;;
    all-testnet)
        echo -e "${YELLOW}Deploying to all testnet chains...${NC}"
        ./deploy.sh eth-testnet $ACTION
        ./deploy.sh bsc-testnet $ACTION
        ./deploy.sh base-testnet $ACTION
        echo -e "${GREEN}All testnet deployments completed!${NC}"
        ;;
    *)
        echo -e "${RED}Error: Invalid network specified${NC}"
        echo "Usage: ./deploy.sh [network] [action]"
        echo "Networks: eth, bsc, base, eth-testnet, bsc-testnet, base-testnet, local, all-mainnet, all-testnet"
        echo "Actions: deploy, verify, both"
        exit 1
        ;;
esac

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Script execution completed!${NC}"
echo -e "${GREEN}========================================${NC}"
