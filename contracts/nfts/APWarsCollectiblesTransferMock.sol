// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./APWarsCollectiblesTransfer.sol";

contract APWarsCollectiblesTransferMock {
    function safeTransferFrom(
        APWarsCollectiblesTransfer _transfer,
        ERC1155 _collectibles,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        _transfer.safeTransferFrom(
            _collectibles,
            _from,
            _to,
            _id,
            _amount,
            _data
        );
    }
}
