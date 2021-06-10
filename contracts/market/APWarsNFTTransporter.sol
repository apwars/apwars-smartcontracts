// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./APWarsMarketAccessControl.sol";

contract APWarsNFTTransporter is APWarsMarketAccessControl, ERC1155Holder {
    using SafeMath for uint256;

    bytes private DEFAULT_MESSAGE;

    address feeAddress;
    uint256 feeAmount;
    address feeTokenAddress;

    event NFTTransporterSetup(
        address feeAddress,
        uint256 feeAmount,
        address feeTokenAddress
    );

    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    function getFeeAmount() public view returns (uint256) {
        return feeAmount;
    }

    function getFeeTokenAddress() public view returns (address) {
        return feeTokenAddress;
    }

    function setup(
        address _feeAddress,
        uint256 _feeAmount,
        address _feeTokenAddress
    ) public onlyRole(CONFIGURATOR_ROLE) {

        feeAddress = _feeAddress;
        feeAmount = _feeAmount;
        feeTokenAddress = _feeTokenAddress;

        emit NFTTransporterSetup(feeAddress, feeAmount, feeTokenAddress);
    }

    function sendNFT(
        address _tokenAddressNFT,
        address _tokenBeneficiary,
        uint256 _tokenId,
        uint256 _quantity
    ) public {

        IERC20 tokenFeeAmount = IERC20(feeTokenAddress);
        IERC1155 tokenAddressNFT = IERC1155(_tokenAddressNFT);

        require(
            tokenFeeAmount.transferFrom(msg.sender, feeAddress, feeAmount),
            "APWarsNFTTransporter:FAIL_TO_TRANSFER_FEE_RATE"
        );
        
        tokenAddressNFT.safeTransferFrom(msg.sender, _tokenBeneficiary, _tokenId, _quantity, DEFAULT_MESSAGE);
    }
}
