// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/VegaToken.sol";
import "../src/YieldFarming.sol";

contract DeployScript is Script {
    // Deployment addresses
    VegaToken public vegaToken;
    YieldFarming public yieldFarming;
    
    // Configuration
    struct DeploymentConfig {
        address treasury;
        address stakingRewards;
        address liquidity;
        address feeRecipient;
        uint256 startBlock;
        uint256 endBlock;
    }
    
    function run() external {
        // Get deployment configuration based on chain
        DeploymentConfig memory config = getConfig();
        
        // Start broadcasting transactions
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VegaToken
        vegaToken = new VegaToken(
            config.treasury,
            config.stakingRewards,
            config.liquidity
        );
        
        console.log("VegaToken deployed at:", address(vegaToken));
        
        // Deploy YieldFarming
        yieldFarming = new YieldFarming(
            vegaToken,
            config.feeRecipient,
            config.startBlock,
            config.endBlock
        );
        
        console.log("YieldFarming deployed at:", address(yieldFarming));
        
        // Setup initial pools
        setupPools();
        
        // Transfer tokens to yield farming contract
        vegaToken.transfer(address(yieldFarming), 10_000_000 * 10**18);
        
        vm.stopBroadcast();
        
        // Log deployment info
        logDeployment();
    }
    
    function getConfig() internal view returns (DeploymentConfig memory) {
        uint256 chainId = block.chainid;
        
        // Ethereum Mainnet
        if (chainId == 1) {
            return DeploymentConfig({
                treasury: vm.envAddress("ETH_TREASURY"),
                stakingRewards: vm.envAddress("ETH_STAKING_REWARDS"),
                liquidity: vm.envAddress("ETH_LIQUIDITY"),
                feeRecipient: vm.envAddress("ETH_FEE_RECIPIENT"),
                startBlock: block.number + 100,
                endBlock: block.number + 2628000 // ~1 year
            });
        }
        // BSC Mainnet
        else if (chainId == 56) {
            return DeploymentConfig({
                treasury: vm.envAddress("BSC_TREASURY"),
                stakingRewards: vm.envAddress("BSC_STAKING_REWARDS"),
                liquidity: vm.envAddress("BSC_LIQUIDITY"),
                feeRecipient: vm.envAddress("BSC_FEE_RECIPIENT"),
                startBlock: block.number + 100,
                endBlock: block.number + 10512000 // ~1 year on BSC
            });
        }
        // Base Mainnet
        else if (chainId == 8453) {
            return DeploymentConfig({
                treasury: vm.envAddress("BASE_TREASURY"),
                stakingRewards: vm.envAddress("BASE_STAKING_REWARDS"),
                liquidity: vm.envAddress("BASE_LIQUIDITY"),
                feeRecipient: vm.envAddress("BASE_FEE_RECIPIENT"),
                startBlock: block.number + 100,
                endBlock: block.number + 15768000 // ~1 year on Base
            });
        }
        // Sepolia Testnet (for testing) - Goerli is deprecated
        else if (chainId == 11155111 || chainId == 5) {
            address testAddress = vm.addr(vm.envUint("PRIVATE_KEY"));
            return DeploymentConfig({
                treasury: testAddress,
                stakingRewards: testAddress,
                liquidity: testAddress,
                feeRecipient: testAddress,
                startBlock: block.number + 10,
                endBlock: block.number + 100000
            });
        }
        // BSC Testnet
        else if (chainId == 97) {
            address testAddress = vm.addr(vm.envUint("PRIVATE_KEY"));
            return DeploymentConfig({
                treasury: testAddress,
                stakingRewards: testAddress,
                liquidity: testAddress,
                feeRecipient: testAddress,
                startBlock: block.number + 10,
                endBlock: block.number + 100000
            });
        }
        // Base Goerli
        else if (chainId == 84531) {
            address testAddress = vm.addr(vm.envUint("PRIVATE_KEY"));
            return DeploymentConfig({
                treasury: testAddress,
                stakingRewards: testAddress,
                liquidity: testAddress,
                feeRecipient: testAddress,
                startBlock: block.number + 10,
                endBlock: block.number + 100000
            });
        }
        // Local/Hardhat
        else {
            address testAddress = vm.addr(vm.envUint("PRIVATE_KEY"));
            return DeploymentConfig({
                treasury: testAddress,
                stakingRewards: testAddress,
                liquidity: testAddress,
                feeRecipient: testAddress,
                startBlock: block.number + 10,
                endBlock: block.number + 100000
            });
        }
    }
    
    function setupPools() internal {
        // Add VEGA staking pool with highest allocation
        yieldFarming.addPool(
            vegaToken,
            1000,  // allocPoint
            0,     // no deposit fee for VEGA
            100,   // 1% withdraw fee
            1000 * 10**18,  // min stake 1000 VEGA
            7 days,         // lock duration
            false
        );
        
        // Additional pools can be added for LP tokens later
        console.log("Initial pools configured");
    }
    
    function logDeployment() internal view {
        console.log("====================================");
        console.log("Deployment Complete!");
        console.log("====================================");
        console.log("Chain ID:", block.chainid);
        console.log("VegaToken:", address(vegaToken));
        console.log("YieldFarming:", address(yieldFarming));
        console.log("Total Supply:", vegaToken.totalSupply());
        console.log("====================================");
    }
}
