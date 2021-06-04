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
        address buyer;
        address seller;
        OrderType orderType;
        OrderStatus orderStatus;
        address tokenAddress;
        uint256 tokenId;
        address tokenPriceAddress;
        uint256 amount;
        uint256 quantity;
    }

    event NewOrder(address indexed sender, uint256 indexed id);

    event OrderExecuted(address indexed sender, uint256 indexed id);

    event OrderCanceled(address indexed sender, uint256 id);

    OrderInfo[] private orders;
    OrderInfo[] private sellOrders;
    OrderInfo[] private buyOrders;
    mapping(address => mapping(address => mapping(uint256 => uint256[]))) ordersMapping;

    address feeAddress;
    address defaultTokenAddress;
    address defaultTokenPriceAddress;
    uint256 swapFeeRate;
    address[] private allowedTokens;
    mapping(address => bool) private allowedTokensMapping;

    event NFTSwapEscrowSetup(
        address feeAddress,
        uint256 swapFeeRate,
        address[] allowedTokens
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

    function getAllowedTokens() public view returns (address[] memory) {
        return allowedTokens;
    }

    function setup(
        address _feeAddress,
        address _defaultTokenAddress,
        address _defaultTokenPriceAddress,
        uint256 _swapFeeRate,
        address[] memory _allowedTokens
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _swapFeeRate <= ONE_HUNDRED_PERCENT,
            "APWarsMarketNFTSwapEscrow:INVALID_SWAP_FEE"
        );

        feeAddress = _feeAddress;
        defaultTokenPriceAddress = _defaultTokenPriceAddress;
        defaultTokenAddress = _defaultTokenAddress;
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

    function addAllowedToken(address _allowedToken)
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
        address _tokenPriceAddress,
        uint256 _amount,
        uint256 _quantity
    ) public returns (uint256) {
        uint256 orderId = orders.length;

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "APWarsMarketNFTSwapEscrow:INVALID_TOKEN_PRICE_ADDRESS"
        );

        OrderInfo memory orderInfo =
            OrderInfo(
                _orderType == OrderType.SELL ? msg.sender : address(0),
                _orderType == OrderType.BUY ? msg.sender : address(0),
                _orderType,
                OrderStatus.OPEN,
                _tokenAddress,
                _tokenId,
                _tokenPriceAddress,
                _amount,
                _quantity
            );

        if (_orderType == OrderType.SELL) {
            IERC1155 token = IERC1155(_tokenAddress);
            token.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _quantity,
                DEFAULT_MESSAGE
            );

            sellOrders.push(orderInfo);
        } else {
            IERC20 tokenPrice = IERC20(_tokenPriceAddress);
            require(
                tokenPrice.transferFrom(
                    msg.sender,
                    address(this),
                    orderInfo.amount.mul(_quantity)
                ),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_WITHDRAW"
            );
            buyOrders.push(orderInfo);
        }

        orders.push(orderInfo);

        emit NewOrder(msg.sender, orderId);

        return orderId;
    }

    function getOrdersLength() public view returns (uint256) {
        return orders.length;
    }

    function getBuyOrdersLength() public view returns (uint256) {
        return buyOrders.length;
    }

    function getSellOrdersLength() public view returns (uint256) {
        return sellOrders.length;
    }

    function getOrderInfo(uint256 _orderId, OrderType _orderType)
        public
        view
        returns (
            address buyer,
            address seller,
            OrderType orderType,
            OrderStatus orderStatus,
            address tokenAddress,
            uint256 tokenId,
            address tokenPriceAddress,
            uint256 amount
        )
    {
        OrderInfo storage orderInfo;

        if (_orderType == OrderType.SELL) {
            orderInfo = sellOrders[_orderId];
        } else {
            orderInfo = buyOrders[_orderId];
        }

        buyer = orderInfo.buyer;
        seller = orderInfo.seller;
        orderType = orderInfo.orderType;
        orderStatus = orderInfo.orderStatus;
        tokenAddress = orderInfo.tokenAddress;
        tokenId = orderInfo.tokenId;
        tokenPriceAddress = orderInfo.tokenPriceAddress;
        amount = orderInfo.amount;
    }

    function executeOrder(uint256 _orderId, uint256 _quantity) public {
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
            tokenPrice.transferFrom(
                tokenWalletOwner,
                tokenBeneficiary,
                netAmount
            ),
            "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_AMOUNT"
        );

        require(
            tokenPrice.transferFrom(tokenWalletOwner, feeAddress, feeAmount),
            "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_FEE_AMOUNT"
        );

        orderInfo.orderStatus = OrderStatus.EXECUTED;

        emit OrderExecuted(msg.sender, _orderId);
    }

    function cancel(uint256 _orderId) public {
        OrderInfo storage orderInfo = orders[_orderId];

        require(
            orderInfo.orderStatus == OrderStatus.OPEN,
            "APWarsMarketNFTSwapEscrow:INVALID_ORDER_STATUS"
        );

        require(
            orderInfo.buyer == msg.sender || orderInfo.seller == msg.sender,
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

        emit OrderCanceled(msg.sender, _orderId);
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
