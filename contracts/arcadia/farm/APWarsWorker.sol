// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IAPWarsWorkerManager.sol";

contract APWarsWorker is AccessControl, ERC1155Holder {
    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    struct AccountInfo {
        uint256 amount;
        uint256 previousClaim;
        uint256 nextClaim;
    }

    bytes private DEFAULT_MESSAGE;

    mapping(address => AccountInfo) public accounts;
    address public workerManagerAddress;
    address public collectibles;
    uint256 public workerId;
    uint256 public minimumBlocks;
    uint256 public reductionRate;

    event NewSetup(
        uint256 workerId,
        uint256 minimumBlocks,
        uint256 reductionRate,
        address workerManagerAddress,
        address collectibles
    );
    event NewClaim(address sender, uint256 amount);
    event NewWithdraw(address sender, address to, uint256 amount);

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsCombinator:INVALID_ROLE");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    function setup(
        uint256 _workerId,
        uint256 _minimumBlocks,
        uint256 _reductionRate,
        address _workerManagerAddress,
        address _collectible
    ) public onlyRole(CONFIGURATOR_ROLE) {
        workerId = _workerId;
        minimumBlocks = _minimumBlocks;
        reductionRate = _reductionRate;
        workerManagerAddress = _workerManagerAddress;
        collectibles = _collectible;

        emit NewSetup(
            workerId,
            minimumBlocks,
            reductionRate,
            workerManagerAddress,
            collectibles
        );
    }

    function getNextClaim(
        uint256 currentBlock,
        uint256 rate,
        uint256 minBlocks,
        uint256 blocks,
        uint256 workersAmount
    ) public pure returns (uint256) {
        uint256 reduction = blocks.mul(rate.mul(workersAmount)).div(
            ONE_HUNDRED_PERCENT
        );

        uint256 newBlockInterval = reduction > blocks
            ? minBlocks
            : blocks.sub(reduction);

        return
            (newBlockInterval < minBlocks ? minBlocks : newBlockInterval).add(
                currentBlock
            );
    }

    function claim() public {
        AccountInfo storage info = accounts[msg.sender];
        IAPWarsWorkerManager workerManager = IAPWarsWorkerManager(
            workerManagerAddress
        );

        (uint256 blocks, uint256 reward, uint256 limit) = workerManager
            .getGeneralConfig(msg.sender, address(this));

        require(block.number >= info.nextClaim, "APWarsWorker:INVALID_BLOCK");

        info.previousClaim = block.number;
        info.nextClaim = getNextClaim(
            block.number,
            reductionRate,
            minimumBlocks,
            blocks,
            info.amount
        );
        info.amount = info.amount.add(reward);

        workerManager.onClaim(msg.sender, address(this));

        emit NewClaim(msg.sender, reward);
    }

    function withdraw(address _to, uint256 _amount) public {
        IAPWarsWorkerManager workerManager = IAPWarsWorkerManager(
            workerManagerAddress
        );
        AccountInfo storage info = accounts[msg.sender];
        IERC1155 token = IERC1155(collectibles);

        require(_amount <= info.amount, "APWarsWorker:INVALID_AMOUNT");

        token.safeTransferFrom(
            address(this),
            _to,
            workerId,
            _amount,
            DEFAULT_MESSAGE
        );

        info.amount = info.amount.sub(_amount);
        workerManager.onWithdraw(msg.sender, address(this));

        emit NewWithdraw(msg.sender, _to, _amount);
    }
}
