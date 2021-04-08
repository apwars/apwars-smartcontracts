// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/IBEP20.sol";
import "../libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../IAPWarsBaseToken.sol";
import "../utils/IAPWarsBurnManager.sol";
import "./APWarsUnitFarmManagerAccessControl.sol";

// APWarsUnitFarmManager is the master of a APWars units tokens.
contract APWarsUnitFarmManager is
    APWarsUnitFarmManagerAccessControl,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IAPWarsBaseToken token;
        IBEP20 lpToken; // Address of LP token contract.
        uint256 tokenPerBlock;
        uint256 allocPoint; // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
        IAPWarsBurnManager burnManager; // This contract will control the deposit fee, but in this conext we will call it burn rate
    }

    // Dev address.
    address public devaddr;
    // Bonus muliplier for early token makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    mapping(address => uint256) public totalAllocPoint;
    // The block number when token mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event BurnedAmount(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 userAmount,
        uint256 burnedAmount,
        uint256 burnRate
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 amountPerBlock);

    constructor(
        address _devaddr,
        address _feeAddress,
        uint256 _startBlock
    ) public {
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        IAPWarsBaseToken _token,
        uint256 _tokenPerBlock,
        uint256 _allocPoint,
        IBEP20 _lpToken,
        IAPWarsBurnManager _burnManager,
        bool _withUpdate
    ) public onlyRole(DEFAULT_ADMIN_ROLE) nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint[address(_token)] = totalAllocPoint[address(_token)].add(
            _allocPoint
        );
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                token: _token,
                tokenPerBlock: _tokenPerBlock,
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                burnManager: _burnManager
            })
        );
    }

    // Update the given pool's token allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IAPWarsBurnManager _burnManager,
        uint256 _tokenPerBlock,
        bool _withUpdate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        if (_withUpdate) {
            massUpdatePools();
        }
        address tokenAddress = address(poolInfo[_pid].token);
        totalAllocPoint[tokenAddress] = totalAllocPoint[tokenAddress]
            .sub(poolInfo[_pid].allocPoint)
            .add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].burnManager = _burnManager;
        poolInfo[_pid].tokenPerBlock = _tokenPerBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending tokens on frontend.
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(pool.tokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint[address(pool.token)]
                );
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(pool.tokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint[address(pool.token)]
            );
        pool.token.mint(devaddr, tokenReward.div(10));
        pool.token.mint(address(this), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to APWarFarmManager for token allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeTokenTransfer(_pid, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            uint16 burnRate =
                pool.burnManager.getBurnRate(address(this), msg.sender, _pid);
            if (burnRate > 0) {
                uint256 burnAmount = _amount.mul(burnRate).div(10000);
                pool.lpToken.safeTransfer(feeAddress, burnAmount);
                user.amount = user.amount.add(_amount).sub(burnAmount);

                pool.burnManager.manageAmount(
                    address(this),
                    msg.sender,
                    _pid,
                    user.amount,
                    burnAmount
                );

                emit BurnedAmount(
                    msg.sender,
                    _pid,
                    _amount,
                    user.amount,
                    burnAmount,
                    burnRate
                );
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from APWarFarmManager.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeTokenTransfer(_pid, msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function getUserAmount(uint256 _pid, address user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][user].amount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(
        uint256 _pid,
        address _to,
        uint256 _amount
    ) internal {
        uint256 tokenBal = poolInfo[_pid].token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBal) {
            transferSuccess = poolInfo[_pid].token.transfer(_to, tokenBal);
        } else {
            transferSuccess = poolInfo[_pid].token.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
}
