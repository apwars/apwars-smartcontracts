// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAPWarsWorkerManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract APWarsWorkerManager is IAPWarsWorkerManager, AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    uint256 public defaultBlocks;
    uint256 public defaultReward;
    uint256 public defaultLimit;

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
        uint256 _defaultLimit
    ) public onlyRole(CONFIGURATOR_ROLE) {
        defaultBlocks = _defaultBlocks;
        defaultReward = _defaultReward;
        defaultLimit = _defaultLimit;
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
        blocks = defaultBlocks;
        reward = defaultReward;
        limit = defaultLimit;
    }

    function onClaim(address _player, address _source) public override {}

    function onWithdraw(address _player, address _source) public override {}
}
