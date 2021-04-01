// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAPWarsBaseToken.sol";

interface IUnit is IAPWarsBaseToken {
    function getAttackPower() external returns (uint256);

    function getDefensePower() external returns (uint256);

    function getTroopImproveFactor() external returns (uint256);
}
