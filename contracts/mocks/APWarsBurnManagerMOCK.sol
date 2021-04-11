// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/IAPWarsBurnManager.sol";
import "../IAPWarsBaseToken.sol";

contract APWarsBurnManagerMOCK is Ownable, IAPWarsBurnManager {
    mapping(address => uint16) private burnRate;
    IAPWarsBaseToken private token;
    bool public autoBurn;
    mapping(address => uint256) private burnedAmount;

    event Burned(
        address farmManager,
        address token,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    event BurnedAll(address token, uint256 burnAmount);

    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view override returns (uint16) {
        return burnRate[_player];
    }

    function getBurnedAmount(address _token)
        external
        view
        override
        returns (uint256)
    {
        return burnedAmount[_token];
    }

    function manageAmount(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external override {
        if (autoBurn) {
            burn(_token);
            emit Burned(
                _farmManager,
                _token,
                _player,
                _pid,
                _userAmount,
                _burnAmount
            );
        } else {
            emit Burned(_farmManager, _token, _player, _pid, _userAmount, 0);
        }
    }

    function setBurnRate(address _player, uint16 _amount) public onlyOwner {
        burnRate[_player] = _amount;
    }

    function setAutoBurn(bool _autoBurn) public onlyOwner {
        autoBurn = _autoBurn;
    }

    function burn(address _token) public override {
        IAPWarsBaseToken token = IAPWarsBaseToken(_token);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);

        burnedAmount[_token] += amount;

        BurnedAll(_token, amount);
    }
}
