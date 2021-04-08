// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAPWarsBurnManager {
    function getBurnRate(
        address _farmManager,
        address _player,
        uint256 _pid
    ) external returns (uint16);

    function manageAmount(
        address _farmManager,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external;
}
