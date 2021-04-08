// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/IAPWarsBurnManager.sol";
import "../IAPWarsBaseToken.sol";

contract APWarsBurnManagerMOCK is Ownable, IAPWarsBurnManager {
    mapping(address => uint16) private burnRate;
    IAPWarsBaseToken private token;

    event Burned(
        address farmManager,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    function getBurnRate(
        address _farmManager,
        address _player,
        uint256 _pid
    ) external override returns (uint16) {
        return burnRate[_player];
    }

    function manageAmount(
        address _farmManager,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external override {
        token.burn(token.balanceOf(address(this)));

        emit Burned(_farmManager, _player, _pid, _userAmount, _burnAmount);
    }

    function setBurnRate(address _player, uint16 _amount) public onlyOwner {
        burnRate[_player] = _amount;
    }

    function setBaseToken(IAPWarsBaseToken _token) public onlyOwner {
        token = _token;
    }
}
