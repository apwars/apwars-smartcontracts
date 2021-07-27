// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAPWarsUnitV2 {
    function getAttackPower() external returns (uint256);

    function getDefensePower() external returns (uint256);

    function getTroopImproveFactor() external returns (uint256);
}
