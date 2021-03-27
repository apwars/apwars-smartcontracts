// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./libs/IBEP20.sol";

interface IAPWarsBaseToken is IBEP20 {
    function burn(uint256 _amount) external;

    function mint(address to, uint256 amount) external;
}
