// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVegaToken.sol";

/**
 * @title VegaToken
 * @notice Advanced multi-chain token with yield farming, staking, and investment features
 * @dev Implements comprehensive DeFi functionalities with security best practices
 */
contract VegaToken is 
    ERC20, 
    ERC20Burnable, 
    ERC20Votes, 
    Ownable, 
    Pausable, 
    ERC20Permit, 
    ReentrancyGuard,
    IVegaToken 
{
    // Constants
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million initial
    
    // Staking parameters
    uint256 public stakingAPY = 800; // 8% APY (basis points)
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public minStakeAmount = 1000 * 10**18;
    uint256 public lockPeriod = 7 days;
    
    // Investment pools
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;
    uint256 public rewardPool;
    
    // Fee structure
    uint256 public transactionFee = 200; // 2% fee
    uint256 public stakingRewardsFee = 300; // 3% to staking rewards
    uint256 public liquidityFee = 200; // 2% to liquidity
    uint256 public burnFee = 100; // 1% burn
    
    // Anti-whale mechanism
    uint256 public maxTransactionAmount = 10_000_000 * 10**18; // 10M tokens max per tx
    uint256 public maxWalletAmount = 50_000_000 * 10**18; // 50M tokens max per wallet
    
    // Mappings
    mapping(address => StakeInfo) public stakes;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromLimits;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalRewardsClaimed;
    
    // Liquidity providers
    mapping(address => bool) public automatedMarketMakerPairs;
    
    // Additional events not in interface
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 totalRewards;
        bool isActive;
    }

    /**
     * @dev Constructor initializes the token with advanced features
     */
    constructor(
        address _treasury,
        address _stakingRewards,
        address _liquidity
    ) 
        ERC20("Vega Protocol Token", "VEGA") 
        ERC20Permit("Vega Protocol Token")
        Ownable(msg.sender)
    {
        require(_treasury != address(0), "Invalid treasury");
        require(_stakingRewards != address(0), "Invalid staking rewards");
        require(_liquidity != address(0), "Invalid liquidity");
        
        // Mint initial supply
        _mint(_treasury, INITIAL_SUPPLY * 40 / 100); // 40% to treasury
        _mint(_stakingRewards, INITIAL_SUPPLY * 30 / 100); // 30% for staking rewards
        _mint(_liquidity, INITIAL_SUPPLY * 20 / 100); // 20% for liquidity
        _mint(msg.sender, INITIAL_SUPPLY * 10 / 100); // 10% to deployer
        
        // Set exclusions
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[_treasury] = true;
        isExcludedFromFees[_stakingRewards] = true;
        isExcludedFromFees[_liquidity] = true;
        isExcludedFromFees[address(this)] = true;
        
        isExcludedFromLimits[msg.sender] = true;
        isExcludedFromLimits[_treasury] = true;
        isExcludedFromLimits[_stakingRewards] = true;
        isExcludedFromLimits[_liquidity] = true;
        isExcludedFromLimits[address(this)] = true;
        
        rewardPool = INITIAL_SUPPLY * 30 / 100;
    }
    
    /**
     * @notice Stake tokens to earn rewards
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount >= minStakeAmount, "Below minimum stake");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Calculate pending rewards if already staking
        if (stakes[msg.sender].isActive) {
            _claimRewards(msg.sender);
        }
        
        // Transfer tokens to contract
        _transfer(msg.sender, address(this), amount);
        
        // Update stake info
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastRewardTime = block.timestamp;
        stakes[msg.sender].isActive = true;
        
        totalStaked += amount;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @notice Unstake tokens and claim rewards
     * @param amount Amount to unstake (0 for all)
     */
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.isActive, "No active stake");
        require(block.timestamp >= userStake.startTime + lockPeriod, "Lock period not met");
        
        uint256 unstakeAmount = amount == 0 ? userStake.amount : amount;
        require(unstakeAmount <= userStake.amount, "Exceeds staked amount");
        
        // Calculate and send rewards
        uint256 rewards = calculateRewards(msg.sender);
        
        // Update stake info
        userStake.amount -= unstakeAmount;
        totalStaked -= unstakeAmount;
        
        if (userStake.amount == 0) {
            userStake.isActive = false;
        }
        
        userStake.lastRewardTime = block.timestamp;
        userStake.totalRewards += rewards;
        
        // Transfer tokens back
        _transfer(address(this), msg.sender, unstakeAmount + rewards);
        totalRewardsDistributed += rewards;
        
        emit Unstaked(msg.sender, unstakeAmount, rewards);
    }
    
    /**
     * @notice Claim staking rewards without unstaking
     */
    function claimRewards() external nonReentrant {
        require(stakes[msg.sender].isActive, "No active stake");
        _claimRewards(msg.sender);
    }
    
    /**
     * @notice Calculate pending rewards for a user
     * @param user Address to calculate rewards for
     */
    function calculateRewards(address user) public view returns (uint256) {
        StakeInfo memory userStake = stakes[user];
        if (!userStake.isActive) return 0;
        
        uint256 timeElapsed = block.timestamp - userStake.lastRewardTime;
        uint256 reward = (userStake.amount * stakingAPY * timeElapsed) / (365 days * BASIS_POINTS);
        
        // Ensure rewards don't exceed pool
        if (reward > rewardPool) {
            reward = rewardPool;
        }
        
        return reward;
    }
    
    /**
     * @notice Get staking information for a user
     */
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 startTime,
        uint256 pendingRewards,
        uint256 totalRewardsClaimed_,
        bool isActive
    ) {
        StakeInfo memory userStake = stakes[user];
        return (
            userStake.amount,
            userStake.startTime,
            calculateRewards(user),
            userStake.totalRewards,
            userStake.isActive
        );
    }
    
    /**
     * @dev Internal function to claim rewards
     */
    function _claimRewards(address user) internal {
        uint256 rewards = calculateRewards(user);
        if (rewards > 0) {
            stakes[user].lastRewardTime = block.timestamp;
            stakes[user].totalRewards += rewards;
            lastClaimTime[user] = block.timestamp;
            totalRewardsClaimed[user] += rewards;
            
            _transfer(address(this), user, rewards);
            totalRewardsDistributed += rewards;
            rewardPool -= rewards;
            
            emit RewardsClaimed(user, rewards);
        }
    }
    
    /**
     * @dev Override transfer to implement fees and limits
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) whenNotPaused {
        // Handle fees for non-excluded addresses
        if (from != address(0) && to != address(0) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            // Check limits
            if (!isExcludedFromLimits[from] && !isExcludedFromLimits[to]) {
                require(amount <= maxTransactionAmount, "Exceeds max transaction");
                if (!automatedMarketMakerPairs[to]) {
                    require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds max wallet");
                }
            }
            
            // Calculate fees
            uint256 totalFees = (amount * (transactionFee + stakingRewardsFee + liquidityFee + burnFee)) / BASIS_POINTS;
            uint256 burnAmount = (amount * burnFee) / BASIS_POINTS;
            uint256 stakingAmount = (amount * stakingRewardsFee) / BASIS_POINTS;
            
            // Burn tokens
            if (burnAmount > 0) {
                _burn(from, burnAmount);
            }
            
            // Add to reward pool
            if (stakingAmount > 0) {
                rewardPool += stakingAmount;
            }
            
            // Adjust transfer amount
            amount = amount - totalFees;
        }
        
        super._update(from, to, amount);
    }
    
    // Admin functions
    
    /**
     * @notice Update staking APY
     * @param newAPY New APY in basis points
     */
    function updateAPY(uint256 newAPY) external onlyOwner {
        require(newAPY <= 5000, "APY too high"); // Max 50%
        stakingAPY = newAPY;
        emit APYUpdated(newAPY);
    }
    
    /**
     * @notice Update fee structure
     */
    function updateFees(
        uint256 _transactionFee,
        uint256 _stakingFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        require(_transactionFee + _stakingFee + _liquidityFee + _burnFee <= 1000, "Total fees too high");
        transactionFee = _transactionFee;
        stakingRewardsFee = _stakingFee;
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        emit FeesUpdated(_transactionFee, _stakingFee, _liquidityFee, _burnFee);
    }
    
    /**
     * @notice Update transaction limits
     */
    function updateLimits(uint256 _maxTransaction, uint256 _maxWallet) external onlyOwner {
        require(_maxTransaction >= totalSupply() / 1000, "Max tx too low");
        require(_maxWallet >= totalSupply() / 100, "Max wallet too low");
        maxTransactionAmount = _maxTransaction;
        maxWalletAmount = _maxWallet;
        emit LimitsUpdated(_maxTransaction, _maxWallet);
    }
    
    /**
     * @notice Set automated market maker pair
     */
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }
    
    /**
     * @notice Exclude from fees
     */
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }
    
    /**
     * @notice Exclude from limits
     */
    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }
    
    /**
     * @notice Add tokens to reward pool
     */
    function addToRewardPool(uint256 amount) external onlyOwner {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, address(this), amount);
        rewardPool += amount;
    }
    
    /**
     * @notice Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Delegate voting power
     */
    function delegateVotingPower(address delegatee) external {
        delegate(delegatee);
    }
    
    /**
     * @notice Get contract statistics
     */
    function getContractStats() external view returns (
        uint256 totalSupply_,
        uint256 totalStaked_,
        uint256 rewardPool_,
        uint256 totalRewardsDistributed_,
        uint256 currentAPY
    ) {
        return (
            totalSupply(),
            totalStaked,
            rewardPool,
            totalRewardsDistributed,
            stakingAPY
        );
    }
    
    // Override required by Solidity for ERC20Permit and Nonces
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
