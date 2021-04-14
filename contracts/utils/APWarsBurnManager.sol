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
    IERC1155 private collectibles;
    mapping(uint256 => uint16) goldSaverConfig;
    uint256[] goldSavers;
    mapping(address => uint256) private burnedAmount;

    event Burned(
        address farmManager,
        address _token,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    event BurnedAll(address token, uint256 burnAmount);

    function checkIfConfigured(uint256 _id) public view returns (bool) {
        for (uint256 i = 0; i < goldSavers.length; i++) {
            if (goldSavers[i] == _id) {
                return true;
            }
        }

        return false;
    }

    function setGoldSaverConfig(uint256 _id, uint16 _amount) public onlyOwner {
        if (!checkIfConfigured(_id)) {
            goldSavers.push(_id);
        }

        goldSaverConfig[_id] = _amount;
    }

    function getGoldSaverConfig(uint256 _id) public view returns (uint16) {
        return goldSaverConfig[_id];
    }

    function getGoldSaverConfigByIndex(uint256 _index)
        public
        view
        returns (uint16)
    {
        return goldSaverConfig[goldSavers[_index]];
    }

    function getPlayerBalanceOfByIndex(address _player, uint256 _index)
        public
        view
        returns (uint256)
    {
        return collectibles.balanceOf(_player, goldSavers[_index]);
    }

    function getPlayerBalanceOfById(address _player, uint256 _id)
        public
        view
        returns (uint256)
    {
        return collectibles.balanceOf(_player, _id);
    }

    function getCompundGoldSaverByPlayer(address _player)
        public
        view
        returns (uint16)
    {
        uint16 goldSaver = 0;
        for (uint256 i = 0; i < goldSavers.length; i++) {
            if (getPlayerBalanceOfByIndex(_player, i) > 0) {
                goldSaver += getGoldSaverConfigByIndex(i);
            }
        }

        return goldSaver;
    }

    function getBurnedAmount(address _token)
        external
        view
        override
        returns (uint256)
    {
        return burnedAmount[_token];
    }

    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view override returns (uint16) {
        uint16 burnRate = ONE_HUNDRED_PERCENT;
        uint16 compoundGoldSaver = getCompundGoldSaverByPlayer(_player);

        if (compoundGoldSaver > burnRate) {
            burnRate = 0;
        } else {
            burnRate -= compoundGoldSaver;
        }

        if (burnRate == ONE_HUNDRED_PERCENT) {
            return ONE_HUNDRED_PERCENT - ONE_PERCENT;
        } else {
            return burnRate;
        }
    }

    function manageAmount(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external override {
        burn(_token);

        emit Burned(
            _farmManager,
            _token,
            _player,
            _pid,
            _userAmount,
            _burnAmount
        );
    }

    function setCollectibles(IERC1155 _collectitles) public onlyOwner {
        collectibles = _collectitles;
    }

    function getCollectibles() public view returns (IERC1155) {
        return collectibles;
    }

    function burn(address _token) public override {
        IAPWarsBaseToken token = IAPWarsBaseToken(_token);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);

        burnedAmount[_token] += amount;

        BurnedAll(_token, amount);
    }
}
