// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract APWarsTokenAccessControl is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOT_MANAGER = keccak256("SNAPSHOT_MANAGER");
    bytes32 public constant PAUSE_MANAGER = keccak256("PAUSE_MANAGER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(SNAPSHOT_MANAGER, _msgSender());
        _setupRole(PAUSE_MANAGER, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsTokenAccessControl: INVALID_ROLE"
        );
        _;
    }
}
