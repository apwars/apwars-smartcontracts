// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./APWarsBaseToken.sol";

contract APWarsGoldToken is APWarsBaseToken {
    constructor(string memory _name, string memory _symbol)
        APWarsBaseToken(_name, _symbol)
    {}
}
