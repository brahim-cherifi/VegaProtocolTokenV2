// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/YieldFarming.sol";
import "../src/VegaToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLPToken is ERC20 {
    constructor() ERC20("Mock LP Token", "MLP") {
        _mint(msg.sender, 1_000_000 * 10**18);
    }
}

contract YieldFarmingTest is Test {
    YieldFarming public yieldFarming;
    VegaToken public vegaToken;
    MockLPToken public lpToken;
    
    address public treasury = address(0x1);
    address public stakingRewards = address(0x2);
    address public liquidity = address(0x3);
    address public feeRecipient = address(0x4);
    address public user1 = address(0x5);
    address public user2 = address(0x6);
    
    uint256 public startBlock;
    uint256 public endBlock;
    
    event PoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    
    function setUp() public {
        // Deploy tokens
        vegaToken = new VegaToken(treasury, stakingRewards, liquidity);
        lpToken = new MockLPToken();
        
        // Setup blocks
        startBlock = block.number + 10;
        endBlock = startBlock + 100000;
        
        // Deploy yield farming
        yieldFarming = new YieldFarming(
            vegaToken,
            feeRecipient,
            startBlock,
            endBlock
        );
        
        // Transfer reward tokens to yield farming
        vegaToken.transfer(address(yieldFarming), 100_000 * 10**18);
        
        // Setup test users
        vegaToken.transfer(user1, 10_000 * 10**18);
        vegaToken.transfer(user2, 10_000 * 10**18);
        lpToken.transfer(user1, 10_000 * 10**18);
        lpToken.transfer(user2, 10_000 * 10**18);
        
        // Add pools
        yieldFarming.addPool(
            vegaToken,      // LP token (using VEGA for simplicity)
            1000,           // allocPoint
            200,            // 2% deposit fee
            300,            // 3% withdraw fee
            100 * 10**18,   // min stake
            7 days,         // lock duration
            false
        );
        
        yieldFarming.addPool(
            IERC20(address(lpToken)),
            500,            // allocPoint
            100,            // 1% deposit fee
            200,            // 2% withdraw fee
            50 * 10**18,    // min stake
            3 days,         // lock duration
            false
        );
    }
    
    function testPoolCreation() public {
        assertEq(yieldFarming.poolLength(), 2);
        
        (
            IERC20 poolToken,
            uint256 allocPoint,
            ,
            ,
            uint256 totalStaked,
            uint256 depositFee,
            uint256 withdrawFee,
            bool isActive,
            uint256 minStake,
            uint256 lockDuration
        ) = yieldFarming.poolInfo(0);
        
        assertEq(address(poolToken), address(vegaToken));
        assertEq(allocPoint, 1000);
        assertEq(totalStaked, 0);
        assertEq(depositFee, 200);
        assertEq(withdrawFee, 300);
        assertTrue(isActive);
        assertEq(minStake, 100 * 10**18);
        assertEq(lockDuration, 7 days);
    }
    
    function testDeposit() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        
        uint256 balanceBefore = vegaToken.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit Deposit(user1, 0, depositAmount);
        
        yieldFarming.deposit(0, depositAmount);
        
        uint256 balanceAfter = vegaToken.balanceOf(user1);
        assertEq(balanceBefore - balanceAfter, depositAmount);
        
        // Check user info
        (uint256 amount, , , , , , ) = yieldFarming.userInfo(0, user1);
        uint256 expectedAfterFee = depositAmount * 9800 / 10000; // 2% fee
        assertEq(amount, expectedAfterFee);
        
        vm.stopPrank();
    }
    
    function testDepositBelowMinimum() public {
        uint256 depositAmount = 50 * 10**18; // Below minimum
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        
        vm.expectRevert("Below minimum stake");
        yieldFarming.deposit(0, depositAmount);
        
        vm.stopPrank();
    }
    
    function testWithdraw() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        
        // Fast forward past lock period
        vm.warp(block.timestamp + 8 days);
        vm.roll(block.number + 1000);
        
        uint256 balanceBefore = vegaToken.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit Withdraw(user1, 0, depositAmount * 9800 / 10000);
        
        yieldFarming.withdraw(0, 0); // Withdraw all
        
        uint256 balanceAfter = vegaToken.balanceOf(user1);
        
        // Should receive amount minus fees
        uint256 depositAfterFee = depositAmount * 9800 / 10000;
        uint256 withdrawAfterFee = depositAfterFee * 9700 / 10000; // 3% withdraw fee
        
        assertTrue(balanceAfter > balanceBefore);
        
        vm.stopPrank();
    }
    
    function testWithdrawBeforeLock() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        
        // Try to withdraw immediately
        vm.expectRevert("Still in lock period");
        yieldFarming.withdraw(0, 100 * 10**18);
        
        vm.stopPrank();
    }
    
    function testPendingRewards() public {
        uint256 depositAmount = 1000 * 10**18;
        
        // Move to start block
        vm.roll(startBlock);
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        vm.stopPrank();
        
        // Fast forward
        vm.roll(block.number + 100);
        
        uint256 pending = yieldFarming.pendingRewards(0, user1);
        assertTrue(pending > 0);
    }
    
    function testClaimRewards() public {
        uint256 depositAmount = 1000 * 10**18;
        
        // Move to start block
        vm.roll(startBlock);
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        
        // Fast forward
        vm.roll(block.number + 100);
        vm.warp(block.timestamp + 1 days);
        
        uint256 pending = yieldFarming.pendingRewards(0, user1);
        uint256 balanceBefore = vegaToken.balanceOf(user1);
        
        yieldFarming.claimRewards(0);
        
        uint256 balanceAfter = vegaToken.balanceOf(user1);
        
        // Should receive rewards
        assertTrue(balanceAfter > balanceBefore);
        
        vm.stopPrank();
    }
    
    function testMultiplePools() public {
        // Deposit in pool 0 (VEGA)
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), 1000 * 10**18);
        yieldFarming.deposit(0, 1000 * 10**18);
        vm.stopPrank();
        
        // Deposit in pool 1 (LP)
        vm.startPrank(user2);
        lpToken.approve(address(yieldFarming), 500 * 10**18);
        yieldFarming.deposit(1, 500 * 10**18);
        vm.stopPrank();
        
        // Check pool states
        (, , , , uint256 totalStaked0, , , , , ) = yieldFarming.poolInfo(0);
        (, , , , uint256 totalStaked1, , , , , ) = yieldFarming.poolInfo(1);
        
        assertTrue(totalStaked0 > 0);
        assertTrue(totalStaked1 > 0);
    }
    
    function testEmergencyWithdraw() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        
        uint256 balanceBefore = vegaToken.balanceOf(user1);
        
        // Emergency withdraw (no rewards, no fees)
        yieldFarming.emergencyWithdraw(0);
        
        uint256 balanceAfter = vegaToken.balanceOf(user1);
        
        // Should get back deposited amount minus deposit fee
        uint256 expectedReturn = depositAmount * 9800 / 10000; // Only deposit fee applied
        assertEq(balanceAfter - balanceBefore, expectedReturn);
        
        // Check user is marked as emergency withdrawn
        assertTrue(yieldFarming.emergencyWithdrawn(user1));
        
        vm.stopPrank();
    }
    
    function testUpdateRewardPerBlock() public {
        uint256 newRate = 200 * 10**18;
        
        yieldFarming.updateRewardPerBlock(newRate);
        assertEq(yieldFarming.rewardPerBlock(), newRate);
    }
    
    function testUpdatePool() public {
        uint256 newAllocPoint = 2000;
        
        yieldFarming.updatePool(0, newAllocPoint, true);
        
        (, uint256 allocPoint, , , , , , , , ) = yieldFarming.poolInfo(0);
        assertEq(allocPoint, newAllocPoint);
    }
    
    function testCompound() public {
        uint256 depositAmount = 1000 * 10**18;
        
        // Move to start block
        vm.roll(startBlock);
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        yieldFarming.enableCompound(0);
        vm.stopPrank();
        
        // Fast forward
        vm.roll(block.number + 100);
        
        // Get initial amount
        (uint256 amountBefore, , , , , , bool hasCompound) = yieldFarming.userInfo(0, user1);
        assertTrue(hasCompound);
        
        // Compound (anyone can call)
        address[] memory users = new address[](1);
        users[0] = user1;
        yieldFarming.compound(0, users);
        
        // Check amount increased
        (uint256 amountAfter, , , , , , ) = yieldFarming.userInfo(0, user1);
        assertTrue(amountAfter > amountBefore);
    }
    
    function testMultiplierTiers() public {
        uint256 depositAmount = 1000 * 10**18;
        
        // Move to start block
        vm.roll(startBlock);
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        vm.stopPrank();
        
        // Check rewards at different time periods
        vm.roll(block.number + 100);
        
        // Initial rewards
        uint256 rewards1 = yieldFarming.pendingRewards(0, user1);
        
        // Fast forward 30 days (should get 1.25x multiplier)
        vm.warp(block.timestamp + 31 days);
        vm.roll(block.number + 100);
        
        uint256 rewards2 = yieldFarming.pendingRewards(0, user1);
        
        // Fast forward 90 days (should get 1.5x multiplier)
        vm.warp(block.timestamp + 91 days);
        vm.roll(block.number + 100);
        
        uint256 rewards3 = yieldFarming.pendingRewards(0, user1);
        
        // Rewards should increase with multiplier
        assertTrue(rewards3 > rewards2);
        assertTrue(rewards2 > rewards1);
    }
    
    function testPauseUnpause() public {
        // Pause
        yieldFarming.pause();
        
        // Try to deposit while paused
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), 1000 * 10**18);
        
        vm.expectRevert();
        yieldFarming.deposit(0, 1000 * 10**18);
        vm.stopPrank();
        
        // Unpause
        yieldFarming.unpause();
        
        // Deposit should work now
        vm.startPrank(user1);
        yieldFarming.deposit(0, 1000 * 10**18);
        vm.stopPrank();
    }
    
    function testFeeCollection() public {
        uint256 depositAmount = 1000 * 10**18;
        
        uint256 feeRecipientBalanceBefore = vegaToken.balanceOf(feeRecipient);
        
        vm.startPrank(user1);
        vegaToken.approve(address(yieldFarming), depositAmount);
        yieldFarming.deposit(0, depositAmount);
        vm.stopPrank();
        
        uint256 feeRecipientBalanceAfter = vegaToken.balanceOf(feeRecipient);
        
        // Fee recipient should receive deposit fee
        uint256 expectedFee = depositAmount * 200 / 10000; // 2% fee
        assertEq(feeRecipientBalanceAfter - feeRecipientBalanceBefore, expectedFee);
    }
}
