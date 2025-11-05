# 🚀 Vega Token Deployment Guide

## Prerequisites

1. **Install Dependencies**
   ```bash
   forge install
   ```

2. **Configure Environment**
   - Copy `.env.example` to `.env`
   - Fill in your configuration:
     - Private key (without 0x prefix)
     - RPC URLs for each network
     - API keys for contract verification
     - Wallet addresses for treasury, staking, liquidity, and fees

## Quick Deployment Commands

### 🧪 Testnet Deployment

1. **Deploy to Goerli (Ethereum Testnet)**
   ```bash
   deploy.bat eth-testnet deploy
   ```

2. **Deploy to BSC Testnet**
   ```bash
   deploy.bat bsc-testnet deploy
   ```

3. **Deploy to Base Goerli**
   ```bash
   deploy.bat base-testnet deploy
   ```

4. **Deploy to All Testnets**
   ```bash
   deploy.bat all-testnet deploy
   ```

### 🌐 Mainnet Deployment

⚠️ **WARNING**: Ensure thorough testing and audit before mainnet deployment!

1. **Deploy to Ethereum Mainnet**
   ```bash
   deploy.bat eth both
   ```

2. **Deploy to BSC Mainnet**
   ```bash
   deploy.bat bsc both
   ```

3. **Deploy to Base Mainnet**
   ```bash
   deploy.bat base both
   ```

4. **Deploy to All Mainnets**
   ```bash
   deploy.bat all-mainnet both
   ```

## Manual Deployment Steps

1. **Set Environment Variables**
   ```bash
   set PRIVATE_KEY=your_private_key_here
   set ETH_RPC_URL=your_eth_rpc_url
   set ETHERSCAN_API_KEY=your_etherscan_key
   ```

2. **Deploy Contracts**
   ```bash
   forge script script/Deploy.s.sol:DeployScript --rpc-url %ETH_RPC_URL% --broadcast --verify -vvvv
   ```

3. **Verify Contracts**
   ```bash
   forge verify-contract CONTRACT_ADDRESS src/VegaToken.sol:VegaToken --chain-id 1 --etherscan-api-key %ETHERSCAN_API_KEY%
   ```

## Post-Deployment Steps

1. **Verify Contract Deployment**
   - Check contract addresses in the deployment output
   - Verify on block explorer (Etherscan/BscScan/BaseScan)

2. **Configure Liquidity Pools**
   - Add liquidity on DEXs (Uniswap/PancakeSwap/BaseSwap)
   - Set automated market maker pairs in the contract

3. **Initialize Yield Farming**
   - Add farming pools for LP tokens
   - Set reward allocations
   - Fund the reward pool

4. **Security Setup**
   - Transfer ownership to multisig wallet
   - Set up monitoring and alerts
   - Configure time locks for admin functions

## Testing Before Deployment

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test
forge test --match-test testStaking

# Run with coverage
forge coverage
```

## Network Configuration

| Network | Chain ID | RPC URL |
|---------|----------|---------|
| Ethereum Mainnet | 1 | https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY |
| BSC Mainnet | 56 | https://bsc-dataseed.binance.org/ |
| Base Mainnet | 8453 | https://mainnet.base.org |
| Goerli Testnet | 5 | https://eth-goerli.g.alchemy.com/v2/YOUR_KEY |
| BSC Testnet | 97 | https://data-seed-prebsc-1-s1.binance.org:8545/ |
| Base Goerli | 84531 | https://goerli.base.org |

## Gas Costs Estimation

| Operation | Estimated Gas | Cost (30 Gwei) |
|-----------|---------------|----------------|
| Token Deployment | ~3,500,000 | ~0.105 ETH |
| YieldFarming Deployment | ~4,000,000 | ~0.12 ETH |
| Stake | ~150,000 | ~0.0045 ETH |
| Unstake | ~200,000 | ~0.006 ETH |
| Transfer | ~65,000 | ~0.00195 ETH |

## Troubleshooting

### Common Issues

1. **"Insufficient funds" error**
   - Ensure your wallet has enough native tokens for gas
   - Add ~0.5 ETH/BNB for deployment

2. **"Contract verification failed"**
   - Double-check your API keys
   - Ensure constructor arguments match

3. **"Transaction reverted"**
   - Check gas limits
   - Verify contract addresses in .env

### Support

- Documentation: See README.md
- Issues: Create an issue on GitHub
- Community: Join our Discord

## Security Checklist

- [ ] Contracts audited by reputable firm
- [ ] Multisig wallet configured
- [ ] Emergency pause tested
- [ ] Monitoring alerts set up
- [ ] Bug bounty program launched
- [ ] Time locks implemented
- [ ] Access controls verified
- [ ] Reentrancy guards tested

---

**Remember**: Always test on testnet first!
