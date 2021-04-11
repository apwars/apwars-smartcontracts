// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "../IAPWarsBaseToken.sol";

interface IAPWarsBurnManager {
    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view returns (uint16);

    function getBurnedAmount(address _token) external view returns (uint256);

    function manageAmount(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external;

    function burn(address _token) external;
}
