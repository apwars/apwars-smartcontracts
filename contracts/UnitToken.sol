// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IUnit.sol";
import "./APWarsBaseToken.sol";

contract UnitToken is IUnit, APWarsBaseToken {
    uint256 private attackPower;
    uint256 private defensePower;
    uint256 private troopImproveFactor;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _attackPower,
        uint256 _defensePower,
        uint256 _troopImproveFactor
    ) APWarsBaseToken(_name, _symbol) {
        attackPower = _attackPower;
        defensePower = _defensePower;
        troopImproveFactor = _troopImproveFactor;
    }

    function getAttackPower() external view override returns (uint256) {
        return attackPower;
    }

    function getDefensePower() external view override returns (uint256) {
        return defensePower;
    }

    function getTroopImproveFactor() external view override returns (uint256) {
        return troopImproveFactor;
    }
}
