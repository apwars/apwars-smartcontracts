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
    IERC1155 collectiblesAddress;
    uint256[] allowedNFTsForFee;
    mapping(uint256 => uint256) priceByNFT;

    event NFTTransporterSetup(
        address feeAddress,
        uint256 feeAmount,
        address feeTokenAddress
    );

    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    function getFeeAmount(address sender)
        public
        view
        returns (uint256 currentFeeAmount, uint256 nftId)
    {
        currentFeeAmount = feeAmount;

        for (uint256 i = 0; i < allowedNFTsForFee.length; i++) {
            if (
                collectiblesAddress.balanceOf(sender, allowedNFTsForFee[i]) > 0
            ) {
                currentFeeAmount = priceByNFT[allowedNFTsForFee[i]];
                nftId = allowedNFTsForFee[i];

                break;
            }
        }
    }

    function getFeeTokenAddress() public view returns (address) {
        return feeTokenAddress;
    }

    function setup(
        address _feeAddress,
        uint256 _feeAmount,
        address _feeTokenAddress,
        IERC1155 _collectiblesAddress,
        uint256[] calldata _allowedNFTsForFee,
        uint256[] calldata _pricesByNFT
    ) public onlyRole(CONFIGURATOR_ROLE) {
        feeAddress = _feeAddress;
        feeAmount = _feeAmount;
        feeTokenAddress = _feeTokenAddress;
        collectiblesAddress = collectiblesAddress;

        for (uint256 i = 0; i < allowedNFTsForFee.length; i++) {
            priceByNFT[allowedNFTsForFee[i]] = 0;
        }

        allowedNFTsForFee = _allowedNFTsForFee;

        for (uint256 i = 0; i < _allowedNFTsForFee.length; i++) {
            priceByNFT[_pricesByNFT[i]] = _pricesByNFT[i];
        }

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

        (uint256 currentFeeAmount, uint256 _tokenFeeId) =
            getFeeAmount(msg.sender);

        if (_tokenFeeId != 0) {
            tokenAddressNFT.safeTransferFrom(
                msg.sender,
                feeAddress,
                _tokenFeeId,
                1,
                DEFAULT_MESSAGE
            );
        }

        require(
            tokenFeeAmount.transferFrom(
                msg.sender,
                feeAddress,
                currentFeeAmount
            ),
            "APWarsNFTTransporter:FAIL_TO_TRANSFER_FEE_RATE"
        );

        tokenAddressNFT.safeTransferFrom(
            msg.sender,
            _tokenBeneficiary,
            _tokenId,
            _quantity,
            DEFAULT_MESSAGE
        );
    }
}
