// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../APWarsFarmManagerV3.sol";

contract APWarsFarmManagerOwner is AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsFarmManagerOwner: INVALID_ROLE"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    function transferOwnership(Ownable _ownable, address _owner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ownable.transferOwnership(_owner);
    }
}
