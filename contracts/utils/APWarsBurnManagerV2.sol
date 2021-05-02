// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../libs/IBEP20.sol";
import "../IAPWarsBaseToken.sol";
import "./IAPWarsBurnManager.sol";

contract APWarsBurnManagerV2 is Ownable, IAPWarsBurnManager {
    uint16 private constant ONE_HUNDRED_PERCENT = 10000;
    uint16 private constant ONE_PERCENT = 100;
    IERC1155 private collectibles;
    mapping(address => uint256) private burnedAmount;
    address previousBurnManager;
    address devAddress;
    mapping(IBEP20 => bool) burnableToken;

    mapping(uint256 => uint16) goldSaverConfig;
    uint256[] goldSavers;

    mapping(address => mapping(uint256 => uint16)) burnSaverAmount;
    mapping(address => uint256[]) burnSavers;

    event Burned(
        address farmManager,
        address token,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    event BurnSaverAmountChanged(address token, uint256 id, uint256 amount);

    event BurnedAll(address token, uint256 burnAmount);

    constructor(address _devAddress) {
        devAddress = _devAddress;
    }

    function setPreviousBurnManager(address _previousBurnManager)
        public
        onlyOwner
    {
        previousBurnManager = _previousBurnManager;
    }

    function getPreviousBurnManager() public view returns (address) {
        return previousBurnManager;
    }

    function setBurnableToken(IBEP20 _token, bool isBurnable) public onlyOwner {
        burnableToken[_token] = isBurnable;
    }

    function isBurnableToken(IBEP20 _token) public view returns (bool) {
        return burnableToken[_token];
    }

    function getPreviousBurnManagerAddress() public view returns (address) {
        return previousBurnManager;
    }

    function getDevAddress() public view returns (address) {
        return devAddress;
    }

    function checkIfBurnSaverIsConfigured(address _token, uint256 _id)
        public
        view
        returns (bool)
    {
        uint256[] storage savers = burnSavers[_token];

        for (uint256 i = 0; i < savers.length; i++) {
            if (savers[i] == _id) {
                return true;
            }
        }

        return false;
    }

    function setBurnSaverAmount(
        address _token,
        uint256 _id,
        uint16 _amount
    ) public onlyOwner {
        if (!checkIfBurnSaverIsConfigured(_token, _id)) {
            burnSavers[_token].push(_id);
        }

        burnSaverAmount[_token][_id] = _amount;

        emit BurnSaverAmountChanged(_token, _id, _amount);
    }

    function getBurnSaverAmountByIndex(address _token, uint256 _index)
        public
        view
        returns (uint16)
    {
        return burnSaverAmount[_token][burnSavers[_token][_index]];
    }

    function getBurnSaverAmount(address _token, uint256 _id)
        public
        view
        returns (uint16)
    {
        return burnSaverAmount[_token][_id];
    }

    function getPlayerBalanceOfByIndex(
        address _token,
        address _player,
        uint256 _index
    ) public view returns (uint256) {
        return collectibles.balanceOf(_player, burnSavers[_token][_index]);
    }

    function getPlayerBalanceOfById(address _player, uint256 _id)
        public
        view
        returns (uint256)
    {
        return collectibles.balanceOf(_player, _id);
    }

    function getCompundBurnSaverByPlayer(address _token, address _player)
        public
        view
        returns (uint16)
    {
        uint16 burnSaver = 0;
        for (uint256 i = 0; i < burnSavers[_token].length; i++) {
            if (getPlayerBalanceOfByIndex(_token, _player, i) > 0) {
                burnSaver += getBurnSaverAmountByIndex(_token, i);
            }
        }

        return burnSaver;
    }

    function getBurnedAmount(address _token)
        external
        view
        override
        returns (uint256)
    {
        return
            burnedAmount[_token] +
            (
                previousBurnManager != address(0)
                    ? IAPWarsBurnManager(previousBurnManager).getBurnedAmount(
                        _token
                    )
                    : 0
            );
    }

    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view override returns (uint16) {
        uint16 burnRate = ONE_HUNDRED_PERCENT;
        uint16 compoundBurnSaver = getCompundBurnSaverByPlayer(_token, _player);

        if (compoundBurnSaver > burnRate) {
            burnRate = 0;
        } else {
            burnRate -= compoundBurnSaver;
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
        IBEP20 token = IBEP20(_token);

        if (!isBurnableToken(token)) {
            token.transfer(devAddress, _burnAmount);
        } else {
            burn(_token);
        }
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
