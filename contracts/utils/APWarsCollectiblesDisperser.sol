// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract APWarsCollectiblesDisperser {
    function batchTransfer(
        IERC1155 _collectibles,
        address[] calldata _addresses,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata data
    ) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _collectibles.safeTransferFrom(
                msg.sender,
                _addresses[i],
                _tokenId,
                _amount,
                data
            );
        }
    }

    function batchTransferMultiple(
        IERC1155 _collectibles,
        address[] calldata _addresses,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata data
    ) public {
        require(
            _addresses.length == _tokenIds.length,
            "Arrays must be the same size"
        );
        require(
            _addresses.length == _amounts.length,
            "Arrays must be the same size"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _collectibles.safeTransferFrom(
                msg.sender,
                _addresses[i],
                _tokenIds[i],
                _amounts[i],
                data
            );
        }
    }
}
