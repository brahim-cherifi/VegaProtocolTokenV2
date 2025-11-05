// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VegaToken.sol";
import "../src/interfaces/IVegaToken.sol";

contract VegaTokenTest is Test {
    VegaToken public token;
    
    address public treasury = address(0x1);
    address public stakingRewards = address(0x2);
    address public liquidity = address(0x3);
    address public user1 = address(0x4);
    address public user2 = address(0x5);
    
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    function setUp() public {
        token = new VegaToken(treasury, stakingRewards, liquidity);
        
        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        
        // Transfer tokens to users for testing
        vm.prank(treasury);
        token.transfer(user1, 100_000 * 10**18);
        
        vm.prank(stakingRewards);
        token.transfer(user2, 100_000 * 10**18);
    }
    
    function testInitialSupply() public {
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }
    
    function testTokenDistribution() public {
        uint256 initialSupply = token.INITIAL_SUPPLY();
        
        // Check initial distribution
        assertEq(token.balanceOf(treasury), initialSupply * 40 / 100 - 100_000 * 10**18);
        assertEq(token.balanceOf(stakingRewards), initialSupply * 30 / 100 - 100_000 * 10**18);
        assertEq(token.balanceOf(liquidity), initialSupply * 20 / 100);
        assertEq(token.balanceOf(address(this)), initialSupply * 10 / 100);
    }
    
    function testStaking() public {
        uint256 stakeAmount = 10_000 * 10**18;
        
        vm.startPrank(user1);
        
        // Approve and stake
        token.approve(address(token), stakeAmount);
        
        vm.expectEmit(true, false, false, true);
        emit Staked(user1, stakeAmount, block.timestamp);
        
        token.stake(stakeAmount);
        
        // Check stake info
        (uint256 stakedAmount, , , , bool isActive) = token.getStakeInfo(user1);
        assertEq(stakedAmount, stakeAmount);
        assertTrue(isActive);
        
        vm.stopPrank();
    }
    
    function testStakingBelowMinimum() public {
        uint256 stakeAmount = 100 * 10**18; // Below minimum
        
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        
        vm.expectRevert("Below minimum stake");
        token.stake(stakeAmount);
        
        vm.stopPrank();
    }
    
    function testUnstakeWithRewards() public {
        uint256 stakeAmount = 10_000 * 10**18;
        
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        
        // Fast forward time
        vm.warp(block.timestamp + 30 days);
        
        // Calculate expected rewards
        uint256 expectedRewards = token.calculateRewards(user1);
        assertTrue(expectedRewards > 0);
        
        // Unstake
        uint256 balanceBefore = token.balanceOf(user1);
        token.unstake(0); // Unstake all
        uint256 balanceAfter = token.balanceOf(user1);
        
        // Check balance increased by stake + rewards
        assertEq(balanceAfter - balanceBefore, stakeAmount + expectedRewards);
        
        vm.stopPrank();
    }
    
    function testUnstakeBeforeLockPeriod() public {
        uint256 stakeAmount = 10_000 * 10**18;
        
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        
        // Try to unstake immediately
        vm.expectRevert("Lock period not met");
        token.unstake(0);
        
        vm.stopPrank();
    }
    
    function testClaimRewards() public {
        uint256 stakeAmount = 10_000 * 10**18;
        
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        
        // Fast forward time
        vm.warp(block.timestamp + 30 days);
        
        uint256 expectedRewards = token.calculateRewards(user1);
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(user1, expectedRewards);
        
        token.claimRewards();
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, expectedRewards);
        
        vm.stopPrank();
    }
    
    function testFeeExclusion() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer between non-excluded addresses (with fees)
        vm.prank(user1);
        uint256 balanceBefore = token.balanceOf(user2);
        token.transfer(user2, transferAmount);
        uint256 balanceAfter = token.balanceOf(user2);
        
        // Should receive less due to fees
        assertTrue(balanceAfter - balanceBefore < transferAmount);
        
        // Exclude user1 from fees
        token.excludeFromFees(user1, true);
        
        // Transfer from excluded address (no fees)
        vm.prank(user1);
        balanceBefore = token.balanceOf(user2);
        token.transfer(user2, transferAmount);
        balanceAfter = token.balanceOf(user2);
        
        // Should receive full amount
        assertEq(balanceAfter - balanceBefore, transferAmount);
    }
    
    function testUpdateAPY() public {
        uint256 newAPY = 1000; // 10%
        
        token.updateAPY(newAPY);
        assertEq(token.stakingAPY(), newAPY);
    }
    
    function testUpdateAPYTooHigh() public {
        uint256 newAPY = 6000; // 60% - too high
        
        vm.expectRevert("APY too high");
        token.updateAPY(newAPY);
    }
    
    function testPauseUnpause() public {
        token.pause();
        
        // Try to transfer while paused
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);
        
        // Unpause
        token.unpause();
        
        // Transfer should work now
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18);
    }
    
    function testDelegateVotingPower() public {
        // Test delegation
        vm.prank(user1);
        token.delegateVotingPower(user2);
        
        // Check that delegation was successful
        assertEq(token.delegates(user1), user2);
        
        // Check voting power
        uint256 user1Balance = token.balanceOf(user1);
        assertEq(token.getVotes(user2), user1Balance);
    }
    
    function testMaxTransactionLimit() public {
        uint256 overLimit = token.maxTransactionAmount() + 1;
        
        // Get enough tokens
        vm.prank(treasury);
        token.transfer(user1, overLimit);
        
        // Try to transfer over limit
        vm.prank(user1);
        vm.expectRevert("Exceeds max transaction");
        token.transfer(user2, overLimit);
    }
    
    function testMaxWalletLimit() public {
        uint256 amount = token.maxWalletAmount() / 2 + 1;
        
        // Get enough tokens
        vm.prank(treasury);
        token.transfer(user1, amount * 2);
        
        // First transfer should work
        vm.prank(user1);
        token.transfer(user2, amount);
        
        // Second transfer should fail (exceeds wallet limit)
        vm.prank(user1);
        vm.expectRevert("Exceeds max wallet");
        token.transfer(user2, amount);
    }
    
    function testBurnFunctionality() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 supplyBefore = token.totalSupply();
        
        vm.prank(user1);
        token.burn(burnAmount);
        
        uint256 supplyAfter = token.totalSupply();
        assertEq(supplyBefore - supplyAfter, burnAmount);
    }
    
    function testAddToRewardPool() public {
        uint256 amount = 10_000 * 10**18;
        uint256 poolBefore = token.rewardPool();
        
        token.approve(address(token), amount);
        token.addToRewardPool(amount);
        
        uint256 poolAfter = token.rewardPool();
        assertEq(poolAfter - poolBefore, amount);
    }
    
    function testMultipleStakers() public {
        uint256 stakeAmount = 10_000 * 10**18;
        
        // User1 stakes
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        vm.stopPrank();
        
        // User2 stakes
        vm.startPrank(user2);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        vm.stopPrank();
        
        // Fast forward and check rewards
        vm.warp(block.timestamp + 30 days);
        
        uint256 rewards1 = token.calculateRewards(user1);
        uint256 rewards2 = token.calculateRewards(user2);
        
        assertTrue(rewards1 > 0);
        assertTrue(rewards2 > 0);
        assertEq(token.totalStaked(), stakeAmount * 2);
    }
    
    function testCompoundingStake() public {
        uint256 initialStake = 10_000 * 10**18;
        
        vm.startPrank(user1);
        token.approve(address(token), initialStake * 2);
        token.stake(initialStake);
        
        // Fast forward and claim rewards
        vm.warp(block.timestamp + 30 days);
        token.claimRewards();
        
        // Stake additional amount
        token.stake(initialStake);
        
        (uint256 stakedAmount, , , , ) = token.getStakeInfo(user1);
        assertEq(stakedAmount, initialStake * 2);
        
        vm.stopPrank();
    }
    
    function testGetContractStats() public {
        (
            uint256 totalSupply,
            uint256 totalStaked,
            uint256 rewardPool,
            uint256 totalRewardsDistributed,
            uint256 currentAPY
        ) = token.getContractStats();
        
        assertEq(totalSupply, token.totalSupply());
        assertEq(totalStaked, token.totalStaked());
        assertEq(rewardPool, token.rewardPool());
        assertEq(totalRewardsDistributed, token.totalRewardsDistributed());
        assertEq(currentAPY, token.stakingAPY());
    }
}
