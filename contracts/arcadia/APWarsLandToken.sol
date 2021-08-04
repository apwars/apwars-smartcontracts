// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

import "../APWarsTokenAccessControl.sol";

contract APWarsLandToken is
    APWarsTokenAccessControl,
    ERC20Snapshot,
    ERC20Pausable,
    ERC20Burnable
{
    string public SYMBOL;
    string public NAME;
    uint8 public DECIMALS = 18;

    using SafeMath for uint256;

    uint256 MAX_SUPPLY = 1500000 * 10**18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        NAME = name;
        SYMBOL = symbol;

        _mint(msg.sender, MAX_SUPPLY);
    }

    function snapshot() public onlyRole(SNAPSHOT_MANAGER) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSE_MANAGER) {
        _pause();
    }

    function unpause() public onlyRole(PAUSE_MANAGER) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Snapshot, ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);
    }
}
