// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVegaToken {
    // Events
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardsClaimed(address indexed user, uint256 amount);
    event APYUpdated(uint256 newAPY);
    event FeesUpdated(uint256 transactionFee, uint256 stakingFee, uint256 liquidityFee, uint256 burnFee);
    event LimitsUpdated(uint256 maxTransaction, uint256 maxWallet);
    
    // Staking functions
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claimRewards() external;
    function calculateRewards(address user) external view returns (uint256);
    
    // View functions
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 startTime,
        uint256 pendingRewards,
        uint256 totalRewardsClaimed,
        bool isActive
    );
    
    function getContractStats() external view returns (
        uint256 totalSupply,
        uint256 totalStaked,
        uint256 rewardPool,
        uint256 totalRewardsDistributed,
        uint256 currentAPY
    );
    
    // Admin functions
    function updateAPY(uint256 newAPY) external;
    function updateFees(
        uint256 _transactionFee,
        uint256 _stakingFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external;
    function updateLimits(uint256 _maxTransaction, uint256 _maxWallet) external;
    function setAutomatedMarketMakerPair(address pair, bool value) external;
    function excludeFromFees(address account, bool excluded) external;
    function excludeFromLimits(address account, bool excluded) external;
    function addToRewardPool(uint256 amount) external;
    function pause() external;
    function unpause() external;
    function delegateVotingPower(address delegatee) external;
}
