// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../inventory/APWarsTokenTransfer.sol";
import "../inventory/APWarsCollectiblesTransfer.sol";
import "../world/APWarsWorldManager.sol";

contract APWarsTreasureHuntSetup is AccessControl, ERC1155Holder {
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    IERC20 private token;
    uint256 private tokenFeeAmount;
    uint256 private tokenFeeOwnerFeePercentage;
    uint256 private gameItemFeeAmount;
    uint256 private gameItemFeeOwnerFeePercentage;
    uint256 private ownerFeePercentage;
    ERC1155 private collectibles;
    uint256 private gameItemId;
    uint256 private rewardAmount;
    APWarsTokenTransfer private tokenTransfer;
    APWarsCollectiblesTransfer private collectiblesTransfer;
    APWarsWorldManager worldManager;
    address devAddress;
    mapping(uint256 => bool) closed;

    bytes private DEFAULT_MESSAGE;

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsTreasureHuntSetup:INVALID_ROLE"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    function setup(
        IERC20 _token,
        ERC1155 _collectibles,
        APWarsTokenTransfer _tokenTransfer,
        APWarsCollectiblesTransfer _collectiblesTransfer,
        address _devAddress,
        APWarsWorldManager _worldManager,
        uint256 _tokenFeeOwnerFeePercentage,
        uint256 _gameItemFeeOwnerFeePercentage,
        uint256 _gameItemId,
        uint256 _rewardAmount,
        uint256 _tokenFeeAmount,
        uint256 _gameItemFeeAmount
    ) public onlyRole(CONFIGURATOR_ROLE) {
        token = _token;
        collectibles = _collectibles;
        tokenTransfer = _tokenTransfer;
        collectiblesTransfer = _collectiblesTransfer;
        devAddress = _devAddress;
        worldManager = _worldManager;
        tokenFeeOwnerFeePercentage = _tokenFeeOwnerFeePercentage;
        gameItemFeeOwnerFeePercentage = _gameItemFeeOwnerFeePercentage;
        gameItemId = _gameItemId;
        rewardAmount = _rewardAmount;
        tokenFeeAmount = _tokenFeeAmount;
        gameItemFeeAmount = _gameItemFeeAmount;
    }

    function closeReward(uint256 _huntId, address _to) public {
        require(!closed[_huntId], "APWarsTreasureHuntSetup:ALREADY_CLOSED");

        closed[_huntId] = true;

        if (_to != address(0)) {
            collectibles.safeTransferFrom(
                address(this),
                _to,
                gameItemId,
                rewardAmount,
                DEFAULT_MESSAGE
            );
        }
    }

    function chargeFee(
        address _sender,
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public {
        address landOwner = worldManager.getLandOwner(_worldId, _x, _y);
        uint256 ownerTokenAmount = tokenFeeAmount.mul(ownerFeePercentage).div(
            ONE_HUNDRED_PERCENT
        );
        uint256 ownerGameItemAmount = gameItemFeeAmount
            .mul(ownerFeePercentage)
            .div(ONE_HUNDRED_PERCENT);
        uint256 devAmount = tokenFeeAmount.sub(ownerTokenAmount);
        uint256 devGameItemAmount = gameItemFeeAmount.sub(ownerGameItemAmount);

        if (landOwner != address(0)) {
            tokenTransfer.transferFrom(
                token,
                _sender,
                landOwner,
                ownerTokenAmount
            );

            collectiblesTransfer.safeTransferFrom(
                collectibles,
                _sender,
                landOwner,
                gameItemId,
                ownerGameItemAmount,
                DEFAULT_MESSAGE
            );
        }

        tokenTransfer.transferFrom(token, _sender, devAddress, devAmount);
        collectiblesTransfer.safeTransferFrom(
            collectibles,
            _sender,
            devAddress,
            gameItemId,
            devGameItemAmount,
            DEFAULT_MESSAGE
        );
    }
}
