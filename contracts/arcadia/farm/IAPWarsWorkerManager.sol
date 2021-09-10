// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAPWarsWorkerManager {
    function getGeneralConfig(address _player, address _source)
        external
        view
        returns (
            uint256 blocks,
            uint256 reward,
            uint256 limit
        );

    function onClaim(address _player, address _source) external;

    function onWithdraw(address _player, address _source) external;
}
