// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

contract VerifyScript is Script {
    function run() external {
        uint256 chainId = block.chainid;
        
        // Read deployment addresses from environment or file
        address vegaToken = vm.envAddress("VEGA_TOKEN_ADDRESS");
        address yieldFarming = vm.envAddress("YIELD_FARMING_ADDRESS");
        
        // Get constructor arguments
        string memory prefix = getEnvPrefix();
        address treasury = vm.envAddress(string.concat(prefix, "_TREASURY"));
        address stakingRewards = vm.envAddress(string.concat(prefix, "_STAKING_REWARDS"));
        address liquidity = vm.envAddress(string.concat(prefix, "_LIQUIDITY"));
        address feeRecipient = vm.envAddress(string.concat(prefix, "_FEE_RECIPIENT"));
        
        console.log("Verifying contracts on chain:", chainId);
        console.log("VegaToken:", vegaToken);
        console.log("YieldFarming:", yieldFarming);
        
        // The actual verification will be done via forge verify-contract command
        // This script just prepares and displays the necessary information
        
        console.log("\nRun the following commands to verify:");
        console.log("\n1. Verify VegaToken:");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(vegaToken),
                " src/VegaToken.sol:VegaToken --chain-id ",
                vm.toString(chainId),
                " --constructor-args ",
                getVegaTokenConstructorArgs(treasury, stakingRewards, liquidity)
            )
        );
        
        console.log("\n2. Verify YieldFarming:");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(yieldFarming),
                " src/YieldFarming.sol:YieldFarming --chain-id ",
                vm.toString(chainId),
                " --constructor-args ",
                getYieldFarmingConstructorArgs(vegaToken, feeRecipient)
            )
        );
    }
    
    function getEnvPrefix() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        
        if (chainId == 1) return "ETH";
        if (chainId == 56) return "BSC";
        if (chainId == 8453) return "BASE";
        if (chainId == 5) return "GOERLI";
        if (chainId == 97) return "BSC_TESTNET";
        if (chainId == 84531) return "BASE_GOERLI";
        
        return "LOCAL";
    }
    
    function getVegaTokenConstructorArgs(
        address treasury,
        address stakingRewards,
        address liquidity
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                vm.toString(abi.encode(treasury, stakingRewards, liquidity))
            )
        );
    }
    
    function getYieldFarmingConstructorArgs(
        address vegaToken,
        address feeRecipient
    ) internal view returns (string memory) {
        uint256 startBlock = block.number + 100;
        uint256 endBlock = startBlock + 2628000; // Adjust based on chain
        
        return string(
            abi.encodePacked(
                vm.toString(abi.encode(vegaToken, feeRecipient, startBlock, endBlock))
            )
        );
    }
}
