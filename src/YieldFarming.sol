// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title YieldFarming
 * @notice Advanced yield farming contract with multiple pools and dynamic rewards
 * @dev Supports LP tokens, flexible reward distribution, and compound features
 */
contract YieldFarming is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    // Pool information
    struct PoolInfo {
        IERC20 lpToken;           // LP token or staking token
        uint256 allocPoint;       // Allocation points for reward distribution
        uint256 lastRewardBlock;  // Last block where rewards were calculated
        uint256 accRewardPerShare; // Accumulated rewards per share
        uint256 totalStaked;      // Total amount staked in this pool
        uint256 depositFee;       // Deposit fee in basis points
        uint256 withdrawFee;      // Withdraw fee in basis points
        bool isActive;            // Pool status
        uint256 minStake;         // Minimum stake amount
        uint256 lockDuration;     // Lock duration in seconds
    }
    
    // User information
    struct UserInfo {
        uint256 amount;           // Staked amount
        uint256 rewardDebt;       // Reward debt for proper distribution
        uint256 depositTime;      // Time of deposit
        uint256 lastClaimTime;    // Last claim time
        uint256 totalClaimed;     // Total rewards claimed
        uint256 pendingRewards;   // Pending rewards to claim
        bool hasCompound;         // Auto-compound enabled
    }
    
    // Multiplier tiers for loyalty rewards
    struct MultiplierTier {
        uint256 minDuration;      // Minimum staking duration
        uint256 multiplier;       // Multiplier in basis points (10000 = 1x)
    }
    
    // Constants
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_DEPOSIT_FEE = 500; // 5%
    uint256 public constant MAX_WITHDRAW_FEE = 500; // 5%
    
    // Token addresses
    IERC20 public rewardToken;
    address public feeRecipient;
    
    // Pool variables
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public poolExists;
    
    // Reward variables
    uint256 public rewardPerBlock = 100 * 10**18; // 100 tokens per block
    uint256 public totalAllocPoint;
    uint256 public startBlock;
    uint256 public endBlock;
    
    // Multiplier system
    MultiplierTier[] public multiplierTiers;
    mapping(address => uint256) public userMultipliers;
    
    // Emergency withdrawal
    mapping(address => bool) public emergencyWithdrawn;
    
    // Events
    event PoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event CompoundEnabled(address indexed user, uint256 indexed pid);
    event RewardRateUpdated(uint256 newRate);
    event PoolUpdated(uint256 indexed pid, uint256 allocPoint);
    
    /**
     * @dev Constructor
     */
    constructor(
        IERC20 _rewardToken,
        address _feeRecipient,
        uint256 _startBlock,
        uint256 _endBlock
    ) Ownable(msg.sender) {
        require(address(_rewardToken) != address(0), "Invalid reward token");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_endBlock > _startBlock, "Invalid block range");
        
        rewardToken = _rewardToken;
        feeRecipient = _feeRecipient;
        startBlock = _startBlock;
        endBlock = _endBlock;
        
        // Initialize multiplier tiers
        multiplierTiers.push(MultiplierTier(0, 10000));        // 1x for 0 days
        multiplierTiers.push(MultiplierTier(7 days, 11000));   // 1.1x for 7 days
        multiplierTiers.push(MultiplierTier(30 days, 12500));  // 1.25x for 30 days
        multiplierTiers.push(MultiplierTier(90 days, 15000));  // 1.5x for 90 days
        multiplierTiers.push(MultiplierTier(180 days, 20000)); // 2x for 180 days
    }
    
    /**
     * @notice Add a new pool
     */
    function addPool(
        IERC20 _lpToken,
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _minStake,
        uint256 _lockDuration,
        bool _withUpdate
    ) external onlyOwner {
        require(address(_lpToken) != address(0), "Invalid LP token");
        require(!poolExists[address(_lpToken)], "Pool already exists");
        require(_depositFee <= MAX_DEPOSIT_FEE, "Deposit fee too high");
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "Withdraw fee too high");
        
        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += _allocPoint;
        
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0,
            totalStaked: 0,
            depositFee: _depositFee,
            withdrawFee: _withdrawFee,
            isActive: true,
            minStake: _minStake,
            lockDuration: _lockDuration
        }));
        
        poolExists[address(_lpToken)] = true;
        emit PoolAdded(poolInfo.length - 1, address(_lpToken), _allocPoint);
    }
    
    /**
     * @notice Update pool allocation points
     */
    function updatePool(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        require(_pid < poolInfo.length, "Invalid pool ID");
        
        if (_withUpdate) {
            massUpdatePools();
        }
        
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        
        emit PoolUpdated(_pid, _allocPoint);
    }
    
    /**
     * @notice Get pending rewards for a user
     */
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.totalStaked;
        
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rewardBlocks = _getRewardBlocks(pool.lastRewardBlock, block.number);
            uint256 reward = (rewardBlocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (reward * 1e12) / lpSupply;
        }
        
        uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        
        // Apply multiplier
        uint256 multiplier = _getUserMultiplier(_user, _pid);
        pending = (pending * multiplier) / BASIS_POINTS;
        
        return pending + user.pendingRewards;
    }
    
    /**
     * @notice Deposit tokens to farm
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant whenNotPaused {
        require(_pid < poolInfo.length, "Invalid pool ID");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(pool.isActive, "Pool not active");
        require(_amount >= pool.minStake || user.amount > 0, "Below minimum stake");
        
        updatePool(_pid);
        
        // Claim pending rewards
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
            if (pending > 0) {
                uint256 multiplier = _getUserMultiplier(msg.sender, _pid);
                pending = (pending * multiplier) / BASIS_POINTS;
                user.pendingRewards += pending;
            }
        }
        
        if (_amount > 0) {
            // Apply deposit fee
            uint256 depositFee = (_amount * pool.depositFee) / BASIS_POINTS;
            uint256 amountAfterFee = _amount - depositFee;
            
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            
            if (depositFee > 0) {
                pool.lpToken.safeTransfer(feeRecipient, depositFee);
            }
            
            user.amount += amountAfterFee;
            pool.totalStaked += amountAfterFee;
            
            if (user.depositTime == 0) {
                user.depositTime = block.timestamp;
            }
        }
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    /**
     * @notice Withdraw tokens from farm
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "Invalid pool ID");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "Insufficient balance");
        require(
            block.timestamp >= user.depositTime + pool.lockDuration,
            "Still in lock period"
        );
        
        updatePool(_pid);
        
        // Calculate pending rewards
        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        if (pending > 0) {
            uint256 multiplier = _getUserMultiplier(msg.sender, _pid);
            pending = (pending * multiplier) / BASIS_POINTS;
            user.pendingRewards += pending;
        }
        
        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalStaked -= _amount;
            
            // Apply withdrawal fee
            uint256 withdrawFee = (_amount * pool.withdrawFee) / BASIS_POINTS;
            uint256 amountAfterFee = _amount - withdrawFee;
            
            pool.lpToken.safeTransfer(msg.sender, amountAfterFee);
            
            if (withdrawFee > 0) {
                pool.lpToken.safeTransfer(feeRecipient, withdrawFee);
            }
        }
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    /**
     * @notice Claim rewards
     */
    function claimRewards(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "Invalid pool ID");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        updatePool(_pid);
        
        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        uint256 multiplier = _getUserMultiplier(msg.sender, _pid);
        pending = (pending * multiplier) / BASIS_POINTS;
        pending += user.pendingRewards;
        
        if (pending > 0) {
            user.pendingRewards = 0;
            user.totalClaimed += pending;
            user.lastClaimTime = block.timestamp;
            
            _safeRewardTransfer(msg.sender, pending);
            emit RewardsClaimed(msg.sender, _pid, pending);
        }
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
    }
    
    /**
     * @notice Enable auto-compound for a pool
     */
    function enableCompound(uint256 _pid) external {
        require(_pid < poolInfo.length, "Invalid pool ID");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "No stake found");
        require(!user.hasCompound, "Already enabled");
        
        user.hasCompound = true;
        emit CompoundEnabled(msg.sender, _pid);
    }
    
    /**
     * @notice Auto-compound rewards (called by keeper)
     */
    function compound(uint256 _pid, address[] calldata users) external {
        require(_pid < poolInfo.length, "Invalid pool ID");
        PoolInfo storage pool = poolInfo[_pid];
        
        updatePool(_pid);
        
        for (uint256 i = 0; i < users.length; i++) {
            UserInfo storage user = userInfo[_pid][users[i]];
            
            if (!user.hasCompound || user.amount == 0) continue;
            
            uint256 pending = (user.amount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
            uint256 multiplier = _getUserMultiplier(users[i], _pid);
            pending = (pending * multiplier) / BASIS_POINTS;
            pending += user.pendingRewards;
            
            if (pending > 0 && address(pool.lpToken) == address(rewardToken)) {
                user.pendingRewards = 0;
                user.amount += pending;
                pool.totalStaked += pending;
                user.totalClaimed += pending;
                user.lastClaimTime = block.timestamp;
            }
            
            user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        }
    }
    
    /**
     * @notice Emergency withdraw without rewards
     */
    function emergencyWithdraw(uint256 _pid) external {
        require(_pid < poolInfo.length, "Invalid pool ID");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        uint256 amount = user.amount;
        require(amount > 0, "No stake found");
        
        user.amount = 0;
        user.rewardDebt = 0;
        user.pendingRewards = 0;
        pool.totalStaked -= amount;
        
        emergencyWithdrawn[msg.sender] = true;
        
        pool.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    /**
     * @notice Update reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit RewardRateUpdated(_rewardPerBlock);
    }
    
    /**
     * @notice Update all pools
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }
    
    /**
     * @notice Update single pool
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 rewardBlocks = _getRewardBlocks(pool.lastRewardBlock, block.number);
        uint256 reward = (rewardBlocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        
        pool.accRewardPerShare += (reward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }
    
    /**
     * @dev Get reward blocks considering start and end blocks
     */
    function _getRewardBlocks(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= startBlock || _from >= endBlock) {
            return 0;
        }
        
        uint256 from = _from > startBlock ? _from : startBlock;
        uint256 to = _to < endBlock ? _to : endBlock;
        
        return to - from;
    }
    
    /**
     * @dev Get user multiplier based on staking duration
     */
    function _getUserMultiplier(address _user, uint256 _pid) internal view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        
        if (user.depositTime == 0) return BASIS_POINTS;
        
        uint256 stakingDuration = block.timestamp - user.depositTime;
        uint256 multiplier = BASIS_POINTS;
        
        for (uint256 i = multiplierTiers.length; i > 0; i--) {
            if (stakingDuration >= multiplierTiers[i - 1].minDuration) {
                multiplier = multiplierTiers[i - 1].multiplier;
                break;
            }
        }
        
        return multiplier;
    }
    
    /**
     * @dev Safe reward transfer
     */
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.safeTransfer(_to, rewardBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
    
    /**
     * @notice Get pool length
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    /**
     * @notice Update fee recipient
     */
    function updateFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @notice Pause farming
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause farming
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
