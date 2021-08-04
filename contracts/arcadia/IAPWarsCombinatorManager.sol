// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "../IAPWarsBaseToken.sol";

interface IAPWarsCombinatorManager {
    function getGeneralConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            uint256 blocks,
            uint256 maxMultiple,
            bool isEnabled
        );

    function getTokenAConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function getTokenBConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function getTokenCConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function getGameItemAConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address collectibles,
            uint256 id,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function getGameItemBConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address collectibles,
            uint256 id,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function getGameItemCConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        external
        view
        returns (
            address collectibles,
            uint256 id,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        );

    function onClaimed(
        address _player,
        address _source,
        uint256 _combinatorId
    ) external;
}
