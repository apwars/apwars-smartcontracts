// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./APWarsMarketAccessControl.sol";

contract APWarsMarketNFTSwapEscrow is APWarsMarketAccessControl, ERC1155Holder {
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes private DEFAULT_MESSAGE;

    enum OrderType {BUY, SELL}
    enum OrderStatus {OPEN, CANCELED, EXECUTED}

    struct OrderInfo {
        address sender;
        address buyer;
        address seller;
        OrderType orderType;
        OrderStatus orderStatus;
        address tokenAddress;
        uint256 tokenId;
        IERC20 tokenPriceAddress;
        uint256 amount;
    }

    event NewOrder(
        uint256 id,
        address indexed sender,
        address buyer,
        address seller,
        OrderType orderType,
        OrderStatus orderStatus,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        IERC20 tokenPriceAddress,
        uint256 amount
    );

    event OrderExecuted(
        uint256 id,
        address indexed sender,
        address tokenWalletOwner,
        address tokenBeneficiary,
        address nftWalletOwner,
        address nftBeneficiary,
        uint256 amount,
        uint256 netAmount,
        uint256 feeAmount
    );

    event OrderCanceled(uint256 id, address indexed sender);

    OrderInfo[] private orders;
    mapping(address => mapping(address => mapping(uint256 => uint256[]))) ordersMapping;

    address feeAddress;
    uint256 swapFeeRate;
    IERC20[] private allowedTokens;
    mapping(IERC20 => bool) private allowedTokensMapping;

    event NFTSwapEscrowSetup(
        address feeAddress,
        uint256 swapFeeRate,
        IERC20[] allowedTokens
    );

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    function getSwapFeeRate() public view returns (uint256) {
        return swapFeeRate;
    }

    function getAllowedTokens() public view returns (IERC20[] memory) {
        return allowedTokens;
    }

    function setup(
        address _feeAddress,
        uint256 _swapFeeRate,
        IERC20[] memory _allowedTokens
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _swapFeeRate <= ONE_HUNDRED_PERCENT,
            "APWarsMarketNFTSwapEscrow:INVALID_SWAP_FEE"
        );

        feeAddress = _feeAddress;
        swapFeeRate = _swapFeeRate;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = false;
        }

        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }

        emit NFTSwapEscrowSetup(_feeAddress, _swapFeeRate, _allowedTokens);
    }

    function setFeeAddress(address _feeAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        feeAddress = _feeAddress;

        emit NFTSwapEscrowSetup(feeAddress, swapFeeRate, allowedTokens);
    }

    function setupSwapFee(uint256 _swapFeeRate)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        require(
            _swapFeeRate <= ONE_HUNDRED_PERCENT,
            "APWarsMarketNFTSwapEscrow:INVALID_SWAP_FEE"
        );

        swapFeeRate = _swapFeeRate;

        emit NFTSwapEscrowSetup(feeAddress, swapFeeRate, allowedTokens);
    }

    function addAllowedToken(IERC20 _allowedToken)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        allowedTokens.push(_allowedToken);
        allowedTokensMapping[_allowedToken] = true;

        emit NFTSwapEscrowSetup(feeAddress, swapFeeRate, allowedTokens);
    }

    function createOrder(
        OrderType _orderType,
        address _tokenAddress,
        uint256 _tokenId,
        IERC20 _tokenPriceAddress,
        uint256 _amount
    ) public returns (uint256) {
        uint256 orderId = orders.length;
        IERC1155 token = IERC1155(_tokenAddress);
        IERC20 tokenPrice = IERC20(_tokenPriceAddress);

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "APWarsMarketNFTSwapEscrow:INVALID_TOKEN_PRICE_ADDRESS"
        );

        OrderInfo memory orderInfo =
            OrderInfo(
                msg.sender,
                _orderType == OrderType.BUY ? msg.sender : address(0),
                _orderType == OrderType.SELL ? msg.sender : address(0),
                _orderType,
                OrderStatus.OPEN,
                _tokenAddress,
                _tokenId,
                _tokenPriceAddress,
                _amount
            );

        if (_orderType == OrderType.SELL) {
            token.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                1,
                DEFAULT_MESSAGE
            );
        } else {
            require(
                tokenPrice.transferFrom(
                    msg.sender,
                    address(this),
                    orderInfo.amount
                ),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_WITHDRAW"
            );
        }

        orders.push(orderInfo);

        emit NewOrder(
            orderId,
            orderInfo.sender,
            orderInfo.buyer,
            orderInfo.seller,
            orderInfo.orderType,
            orderInfo.orderStatus,
            orderInfo.tokenAddress,
            orderInfo.tokenId,
            orderInfo.tokenPriceAddress,
            orderInfo.amount
        );

        ordersMapping[msg.sender][orderInfo.tokenAddress][orderInfo.tokenId]
            .push(orderId);

        return orderId;
    }

    function getOrdersLength() public view returns (uint256) {
        return orders.length;
    }

    function getOrderId(
        address _sender,
        address _tokenAddress,
        uint256 _tokenId
    ) public view returns (uint256[] memory) {
        return ordersMapping[_sender][_tokenAddress][_tokenId];
    }

    function getOrderInfo(uint256 _orderId)
        public
        view
        returns (
            address sender,
            address buyer,
            address seller,
            OrderType orderType,
            OrderStatus orderStatus,
            address tokenAddress,
            uint256 tokenId,
            IERC20 tokenPriceAddress,
            uint256 amount
        )
    {
        OrderInfo storage orderInfo = orders[_orderId];

        sender = orderInfo.sender;
        buyer = orderInfo.buyer;
        seller = orderInfo.seller;
        orderType = orderInfo.orderType;
        orderStatus = orderInfo.orderStatus;
        tokenAddress = orderInfo.tokenAddress;
        tokenId = orderInfo.tokenId;
        tokenPriceAddress = orderInfo.tokenPriceAddress;
        amount = orderInfo.amount;
    }

    function executeOrder(uint256 _orderId) public {
        OrderInfo storage orderInfo = orders[_orderId];

        IERC20 tokenPrice = IERC20(orderInfo.tokenPriceAddress);
        IERC1155 token = IERC1155(orderInfo.tokenAddress);

        address tokenWalletOwner;
        address tokenBeneficiary;
        address nftWalletOwner;
        address nftBeneficiary;

        if (orderInfo.orderType == OrderType.SELL) {
            orderInfo.buyer = msg.sender;

            tokenWalletOwner = orderInfo.buyer;
            nftWalletOwner = address(this);
            tokenBeneficiary = orderInfo.seller;
            nftBeneficiary = orderInfo.buyer;
        } else {
            orderInfo.seller = msg.sender;

            tokenWalletOwner = address(this);
            nftWalletOwner = orderInfo.seller;
            tokenBeneficiary = orderInfo.seller;
            nftBeneficiary = orderInfo.buyer;
        }

        token.safeTransferFrom(
            nftWalletOwner,
            nftBeneficiary,
            orderInfo.tokenId,
            1,
            DEFAULT_MESSAGE
        );

        (uint256 netAmount, uint256 feeAmount) =
            getOrderAmountInfo(orderInfo.amount);

        require(
            tokenPrice.transfer(
                tokenBeneficiary,
                netAmount
            ),
            "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_AMOUNT"
        );

        require(
            tokenPrice.transfer(feeAddress, feeAmount),
            "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_FEE_AMOUNT"
        );

        orderInfo.orderStatus = OrderStatus.EXECUTED;

        emit OrderExecuted(
            _orderId,
            msg.sender,
            tokenWalletOwner,
            tokenBeneficiary,
            nftWalletOwner,
            nftBeneficiary,
            orderInfo.amount,
            netAmount,
            feeAmount
        );
    }

    function cancel(uint256 _orderId) public {
        OrderInfo storage orderInfo = orders[_orderId];

        require(
            orderInfo.orderStatus == OrderStatus.OPEN,
            "APWarsMarketNFTSwapEscrow:INVALID_ORDER_STATUS"
        );

        require(
            orderInfo.sender == msg.sender,
            "APWarsMarketNFTSwapEscrow:INVALID_SENDER"
        );

        if (orderInfo.orderType == OrderType.SELL) {
            IERC1155 token = IERC1155(orderInfo.tokenAddress);
            token.safeTransferFrom(
                address(this),
                msg.sender,
                orderInfo.tokenId,
                1,
                DEFAULT_MESSAGE
            );
        } else {
            IERC20 tokenPrice = IERC20(orderInfo.tokenPriceAddress);

            require(
                tokenPrice.transfer(msg.sender, orderInfo.amount),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_WITHDRAW"
            );
        }

        orderInfo.orderStatus = OrderStatus.CANCELED;

        emit OrderCanceled(_orderId, msg.sender);
    }

    function getFeeAndNetAmount(uint256 _amount, uint256 fee)
        public
        pure
        returns (uint256 netAmount, uint256 feeAmount)
    {
        feeAmount = _amount.mul(fee).div(ONE_HUNDRED_PERCENT);
        netAmount = _amount.sub(feeAmount);
    }

    function getOrderAmountInfo(uint256 _amount)
        public
        view
        returns (uint256 netAmount, uint256 feeAmount)
    {
        (netAmount, feeAmount) = getFeeAndNetAmount(_amount, swapFeeRate);
    }
}
