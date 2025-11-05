# 🚀 Vega Protocol Token (VEGA)

A next-generation multi-chain DeFi token with advanced yield farming, staking mechanisms, and investment features. Built with Solidity and deployable on Ethereum, BSC, and Base networks.

## 🌟 Features

### Core Token Features
- **ERC20 Compliant**: Full ERC20 standard implementation
- **Multi-Chain Support**: Deploy on Ethereum, BSC, and Base
- **Deflationary Mechanism**: Built-in burn functionality
- **Snapshot Capability**: On-chain voting and governance support
- **Pausable**: Emergency pause functionality for security
- **Permit Support**: Gasless transactions via ERC20 Permit

### Advanced Investment Features

#### 🔒 Staking System
- **High Yield APY**: Dynamic APY rates (default 8%)
- **Lock Period**: 7-day minimum lock for security
- **Compound Interest**: Automatic reward calculation
- **Flexible Unstaking**: Partial or full unstaking options
- **Reward Claims**: Claim rewards without unstaking

#### 🌾 Yield Farming
- **Multiple Pools**: Support for various LP tokens
- **Dynamic Rewards**: Time-based multiplier tiers
- **Auto-Compound**: Optional automatic reward reinvestment
- **Flexible Lock Periods**: Customizable per pool
- **Emergency Withdrawal**: Safety mechanism for users

#### 💰 Fee Structure
- **Transaction Fee**: 2% (redistributed to ecosystem)
- **Staking Rewards**: 3% (added to reward pool)
- **Liquidity Fee**: 2% (for liquidity provision)
- **Burn Fee**: 1% (deflationary mechanism)

#### 🛡️ Security Features
- **Anti-Whale Protection**: Transaction and wallet limits
- **Reentrancy Guards**: Protection against attacks
- **Fee Exclusion**: Whitelist for special addresses
- **Ownership Controls**: Multi-level access control

## 📊 Token Distribution

- **Total Supply**: 1,000,000,000 VEGA (1 Billion)
- **Initial Supply**: 100,000,000 VEGA (100 Million)
  - Treasury: 40%
  - Staking Rewards: 30%
  - Liquidity: 20%
  - Team/Development: 10%

## 🛠️ Technology Stack

- **Smart Contracts**: Solidity ^0.8.20
- **Framework**: Foundry
- **Testing**: Forge Test Suite
- **Libraries**: OpenZeppelin Contracts v5
- **Networks**: Ethereum, BSC, Base

## 📦 Installation

### Prerequisites

1. Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Clone the repository:
```bash
git clone https://github.com/your-repo/vegatoken.git
cd vegatoken
```

3. Install dependencies:
```bash
forge install
```

4. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

## 🚀 Deployment

### Local Testing
```bash
# Run tests
forge test

# Run with coverage
forge coverage

# Gas optimization report
forge test --gas-report
```

### Testnet Deployment

1. Configure your `.env` file with:
   - Private key
   - RPC URLs
   - API keys for verification
   - Wallet addresses

2. Deploy to testnet:
```bash
# Deploy to Goerli (Ethereum testnet)
./deploy.bat eth-testnet deploy

# Deploy to BSC testnet
./deploy.bat bsc-testnet deploy

# Deploy to Base Goerli
./deploy.bat base-testnet deploy

# Deploy to all testnets
./deploy.bat all-testnet deploy
```

### Mainnet Deployment

⚠️ **Warning**: Ensure thorough testing and audit before mainnet deployment

```bash
# Deploy to Ethereum
./deploy.bat eth both

# Deploy to BSC
./deploy.bat bsc both

# Deploy to Base
./deploy.bat base both

# Deploy to all mainnets
./deploy.bat all-mainnet both
```

### Contract Verification

Contracts are automatically verified during deployment if API keys are configured. Manual verification:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/VegaToken.sol:VegaToken \
  --chain-id <CHAIN_ID> \
  --constructor-args <ARGS>
```

## 📝 Smart Contract Architecture

### VegaToken.sol
Main token contract with:
- ERC20 implementation
- Staking mechanism
- Fee distribution
- Anti-whale protection
- Snapshot functionality

### YieldFarming.sol
Advanced farming contract with:
- Multi-pool support
- Dynamic reward calculation
- Time-based multipliers
- Auto-compound feature
- Emergency withdrawal

### Key Functions

#### Staking
```solidity
stake(uint256 amount) - Stake tokens
unstake(uint256 amount) - Unstake tokens
claimRewards() - Claim pending rewards
calculateRewards(address user) - View pending rewards
```

#### Yield Farming
```solidity
deposit(uint256 pid, uint256 amount) - Deposit to pool
withdraw(uint256 pid, uint256 amount) - Withdraw from pool
claimRewards(uint256 pid) - Claim farming rewards
pendingRewards(uint256 pid, address user) - View pending rewards
```

## 🔒 Security Considerations

1. **Auditing**: Contracts should be audited before mainnet deployment
2. **Time Locks**: Consider implementing time locks for admin functions
3. **Multi-Sig**: Use multi-signature wallets for ownership
4. **Monitoring**: Set up monitoring for unusual activities
5. **Bug Bounty**: Consider a bug bounty program

## 📈 Yield Farming Multipliers

Staking duration multipliers:
- 0-7 days: 1.0x
- 7-30 days: 1.1x
- 30-90 days: 1.25x
- 90-180 days: 1.5x
- 180+ days: 2.0x

## 🧪 Testing

Run comprehensive test suite:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/VegaToken.t.sol

# Run with verbosity
forge test -vvvv

# Fork testing
forge test --fork-url <RPC_URL>
```

## 📊 Gas Optimization

The contracts are optimized for gas efficiency:
- Optimizer runs: 200
- Efficient storage packing
- Minimal external calls
- Batch operations where possible

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## ⚠️ Disclaimer

This is experimental software. Use at your own risk. The developers are not responsible for any losses incurred through use of this software. Always do your own research and consider getting a professional audit before deploying to mainnet.

## 📞 Support

- Documentation: [docs.vegatoken.io](#)
- Discord: [discord.gg/vegatoken](#)
- Twitter: [@VegaToken](#)
- Email: support@vegatoken.io

## 🗺️ Roadmap

### Phase 1 - Launch (Q1 2025)
- ✅ Smart contract development
- ✅ Testing suite
- ✅ Multi-chain deployment scripts
- 🔄 Security audit
- 🔄 Testnet deployment

### Phase 2 - Growth (Q2 2025)
- [ ] Mainnet launch
- [ ] DEX listings
- [ ] Liquidity provision
- [ ] Staking platform UI
- [ ] Partnership integrations

### Phase 3 - Expansion (Q3 2025)
- [ ] Cross-chain bridge
- [ ] Governance implementation
- [ ] Additional yield strategies
- [ ] Mobile app
- [ ] Advanced DeFi integrations

### Phase 4 - Ecosystem (Q4 2025)
- [ ] DAO formation
- [ ] Grant program
- [ ] Developer SDK
- [ ] Enterprise solutions
- [ ] Global expansion

---

Built with ❤️ by the Vega Protocol Team
