// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract APWarsCollectiblesTransfer is AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    event NewTransfer(
        ERC1155 collectibles,
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 amount
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TRANSFER_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsCollectiblesTransfer: INVALID_ROLE"
        );
        _;
    }

    function safeTransferFrom(
        ERC1155 _collectibles,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyRole(TRANSFER_ROLE) {
        require(_from == tx.origin, "_from != tx.origin");
        _collectibles.safeTransferFrom(_from, _to, _id, _amount, _data);

        emit NewTransfer(_collectibles, msg.sender, _from, _to, _id, _amount);
    }
}
