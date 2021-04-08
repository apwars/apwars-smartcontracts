// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../IAPWarsBaseToken.sol";
import "./IAPWarsBurnManager.sol";

contract APWarsBurnManager is Ownable, IAPWarsBurnManager {
    uint16 private constant ONE_HUNDRED_PERCENT = 10000;
    uint16 private constant ONE_PERCENT = 100;
    IAPWarsBaseToken private token;
    IERC1155 private collectibles;
    mapping(uint256 => uint16) goldSaverConfig;
    uint256[] goldSavers;

    event Burned(
        address farmManager,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    function _addToGoldSaverArray(uint256 _id) internal {
        for (uint256 i = 0; i < goldSavers.length; i++) {
            if (goldSavers[i] == _id) {
                return;
            }
        }

        goldSavers.push(_id);
    }

    function setGoldSaverConfig(uint256 _id, uint16 _amount) public {
        _addToGoldSaverArray(_id);
        goldSaverConfig[_id] = _amount;
    }

    function getBurnRate(
        address _farmManager,
        address _player,
        uint256 _pid
    ) external view override returns (uint16) {
        uint16 burnRate = ONE_HUNDRED_PERCENT;

        for (uint256 i = 0; i < goldSavers.length; i++) {
            if (collectibles.balanceOf(_player, goldSavers[i]) > 0) {
                if (goldSaverConfig[i] > burnRate) {
                    burnRate = 0;
                } else {
                    burnRate -= goldSaverConfig[i];
                }
            }
        }

        if (burnRate == ONE_HUNDRED_PERCENT) {
            return ONE_HUNDRED_PERCENT - ONE_PERCENT;
        } else {
            return burnRate;
        }
    }

    function manageAmount(
        address _farmManager,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external override {
        token.burn(_burnAmount);

        emit Burned(_farmManager, _player, _pid, _userAmount, _burnAmount);
    }

    function setBaseToken(IAPWarsBaseToken _token) public onlyOwner {
        token = _token;
    }

    function setCollectibles(IERC1155 _collectitles) public onlyOwner {
        collectibles = _collectitles;
    }
}
