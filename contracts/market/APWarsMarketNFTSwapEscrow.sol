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
        uint256 orderId;
        address sender;
        OrderType orderType;
        OrderStatus orderStatus;
        address tokenAddress;
        uint256 tokenId;
        address tokenPriceAddress;
        uint256 amount;
        uint256 quantity;
        uint256 remaining;
        uint256 feeAmount;
        uint256 index;
    }

    event NewOrder(address indexed sender, uint256 indexed id);

    event OrderExecuted(address indexed sender, uint256 indexed id);

    event OrderCanceled(address indexed sender, uint256 id);

    event OrderRemoved(address indexed sender, uint256 id);

    OrderInfo[] private orders;
    uint256[] private sellOrders;
    uint256[] private buyOrders;
    mapping(address => mapping(address => mapping(uint256 => uint256[]))) ordersMapping;

    address feeAddress;
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
        uint256 _swapFeeRate,
        address[] memory _allowedTokens
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
        (uint256 totalAmount, uint256 feeAmount) = getOrderAmountInfo(_amount);

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "APWarsMarketNFTSwapEscrow:INVALID_TOKEN_PRICE_ADDRESS"
        );

        OrderInfo memory orderInfo =
            OrderInfo(
                orderId,
                msg.sender,
                _orderType,
                OrderStatus.OPEN,
                _tokenAddress,
                _tokenId,
                _tokenPriceAddress,
                _amount,
                _quantity,
                _quantity,
                feeAmount,
                0
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
            orderInfo.index = sellOrders.length;
            sellOrders.push(orderInfo.orderId);
        } else {
            IERC20 tokenPrice = IERC20(_tokenPriceAddress);
            require(
                tokenPrice.transferFrom(
                    msg.sender,
                    address(this),
                    totalAmount.mul(_quantity)
                ),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_WITHDRAW"
            );
            orderInfo.index = buyOrders.length;
            buyOrders.push(orderInfo.orderId);
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

    function getOrderInfo(uint256 _orderId)
        public
        view
        returns (
            uint256 orderId,
            address sender,
            OrderType orderType,
            OrderStatus orderStatus,
            address tokenAddress,
            uint256 tokenId,
            address tokenPriceAddress,
            uint256 amount,
            uint256 quantity,
            uint256 feeAmount,
            uint256 totalAmount
        )
    {
        OrderInfo storage orderInfo = orders[_orderId];

        orderId = orderInfo.orderId;
        sender = orderInfo.sender;
        orderType = orderInfo.orderType;
        orderStatus = orderInfo.orderStatus;
        tokenAddress = orderInfo.tokenAddress;
        tokenId = orderInfo.tokenId;
        tokenPriceAddress = orderInfo.tokenPriceAddress;
        amount = orderInfo.amount;
        feeAmount = orderInfo.feeAmount;
        quantity = orderInfo.quantity;
        totalAmount = orderInfo.amount.add(orderInfo.feeAmount);
    }

    function getBuyOrderId(uint256 _orderIndex) public view returns (uint256) {
        return buyOrders[_orderIndex];
    }

    function getSellOrderId(uint256 _orderIndex) public view returns (uint256) {
        return sellOrders[_orderIndex];
    }

    function removeFromArray(OrderInfo memory orderInfo) internal {
        if (orderInfo.orderStatus != OrderStatus.OPEN) {
            if (orderInfo.orderType == OrderType.BUY) {
                buyOrders[orderInfo.index] = buyOrders[buyOrders.length - 1];
                buyOrders.pop();
            } else {
                sellOrders[orderInfo.index] = sellOrders[sellOrders.length - 1];
                sellOrders.pop();
            }

            OrderRemoved(msg.sender, orderInfo.orderId);
        }
    }

    function executeOrder(uint256 _orderId, uint256 _quantity) public {
        OrderInfo storage orderInfo = orders[_orderId];

        require(
            orderInfo.orderStatus == OrderStatus.OPEN,
            "APWarsMarketNFTSwapEscrow:INVALID_ORDER_STATUS"
        );

        require(
            orderInfo.quantity >= _quantity,
            "APWarsMarketNFTSwapEscrow:INVALID_QUANTITY"
        );

        IERC20 tokenPrice = IERC20(orderInfo.tokenPriceAddress);
        IERC1155 token = IERC1155(orderInfo.tokenAddress);

        address tokenWalletOwner;
        address tokenBeneficiary;
        address nftWalletOwner;
        address nftBeneficiary;

        if (orderInfo.orderType == OrderType.SELL) {
            tokenWalletOwner = msg.sender;
            nftWalletOwner = address(this);
            tokenBeneficiary = orderInfo.sender;
            nftBeneficiary = msg.sender;
        } else {
            tokenWalletOwner = address(this);
            nftWalletOwner = msg.sender;
            tokenBeneficiary = msg.sender;
            nftBeneficiary = orderInfo.sender;
        }

        token.safeTransferFrom(
            nftWalletOwner,
            nftBeneficiary,
            orderInfo.tokenId,
            _quantity,
            DEFAULT_MESSAGE
        );

        uint256 payment = orderInfo.amount.mul(_quantity);
        uint256 fee = orderInfo.feeAmount.mul(_quantity);

        if (orderInfo.orderType == OrderType.SELL) {
            require(
                tokenPrice.transferFrom(msg.sender, tokenBeneficiary, payment),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_AMOUNT"
            );
            require(
                tokenPrice.transferFrom(msg.sender, address(this), fee),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_FEE_AMOUNT"
            );
        } else {
            require(
                tokenPrice.transfer(tokenBeneficiary, payment),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_AMOUNT"
            );

            require(
                tokenPrice.transfer(feeAddress, fee),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_TRANSFER_FEE_AMOUNT"
            );
        }

        orderInfo.quantity = orderInfo.quantity.sub(_quantity);
        orderInfo.orderStatus = orderInfo.quantity == 0
            ? OrderStatus.EXECUTED
            : orderInfo.orderStatus;

        removeFromArray(orderInfo);
        emit OrderExecuted(msg.sender, _orderId);
    }

    function cancelOrder(uint256 _orderId) public {
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
                orderInfo.sender,
                orderInfo.tokenId,
                orderInfo.quantity,
                DEFAULT_MESSAGE
            );
        } else {
            IERC20 tokenPrice = IERC20(orderInfo.tokenPriceAddress);

            uint256 totalAmount =
                orderInfo.amount.add(orderInfo.feeAmount).mul(
                    orderInfo.quantity
                );

            require(
                tokenPrice.transfer(orderInfo.sender, totalAmount),
                "APWarsMarketNFTSwapEscrow:FAIL_TO_WITHDRAW"
            );
        }

        orderInfo.orderStatus = OrderStatus.CANCELED;
        removeFromArray(orderInfo);

        emit OrderCanceled(orderInfo.sender, _orderId);
    }

    function getOrderAmountInfo(uint256 _amount)
        public
        view
        returns (uint256 totalAmount, uint256 feeAmount)
    {
        feeAmount = _amount.mul(swapFeeRate).div(ONE_HUNDRED_PERCENT);
        totalAmount = _amount.add(feeAmount);
    }
}
