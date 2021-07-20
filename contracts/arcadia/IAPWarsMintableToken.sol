// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "../IAPWarsBaseToken.sol";

interface IAPWarsMintableToken {
    function mint(uint256 _amount) external;
}
