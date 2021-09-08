// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../APWarsFarmManagerV3.sol";
import "./APWarsOwnerAccessControl.sol";

contract APWarsFarmManagerOwner is APWarsOwnerAccessControl {
    function transferOwnership(Ownable _ownable, address _owner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ownable.transferOwnership(_owner);
    }
}
