// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAPWarsWorkerManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract APWarsWorkerManager is IAPWarsWorkerManager, AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 public defaultBlocks;
    uint256 public defaultReward;
    uint256 public defaultLimit;
    address public collectibles;
    uint256[] public gameItems;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsCombinatorManager:INVALID_ROLE"
        );
        _;
    }

    function setup(
        uint256 _defaultBlocks,
        uint256 _defaultReward,
        uint256 _defaultLimit,
        address _collectibles,
        uint256[] calldata _gameItems
    ) public onlyRole(CONFIGURATOR_ROLE) {
        defaultBlocks = _defaultBlocks;
        defaultReward = _defaultReward;
        defaultLimit = _defaultLimit;
        collectibles = _collectibles;
        gameItems = _gameItems;
    }

    function getGeneralConfig(address _player, address _source)
        external
        view
        override
        returns (
            uint256 blocks,
            uint256 reward,
            uint256 limit
        )
    {
        reward = defaultReward;
        IERC1155 token = IERC1155(collectibles);

        for (uint256 i = 0; i < gameItems.length; i++) {
            if (token.balanceOf(_player, gameItems[i]) > 0) {
                reward = defaultReward.mul(2);
                break;
            }
        }

        blocks = defaultBlocks;
        limit = defaultLimit;
    }

    function onClaim(address _player, address _source) public override {}

    function onWithdraw(address _player, address _source) public override {}
}
