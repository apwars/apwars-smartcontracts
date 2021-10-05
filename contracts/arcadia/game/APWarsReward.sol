// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

contract APWarsReward {
    bytes32 public salt = keccak256("SALT");

    constructor() {}

    function check(uint256 _nonce)
        external
        view
        returns (bytes4 result, bool check)
    {
        bytes32 hash = keccak256(abi.encodePacked(salt, _nonce));

        return (bytes4(hash), bytes4(hash) == 0x0);
    }
}
