// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IAPWarsMintableToken.sol";

contract APWarsLandSale is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant FIVE_PERCENT = 10**3 / 2;
    uint256 public constant PRICE_WLAND = 15 * 10**17;

    bytes private DEFAULT_MESSAGE;

    mapping(uint256 => uint256) public priceTicket;
    mapping(bytes32 => address) public referral;
    uint256 public wLANDTotalAmount;
    uint256 public wLANDSoldAmount;
    uint256 public busdTotalAmount;
    address public collectibles;
    address public wLAND;
    address public busd;
    address public dev;

    event NewSell(address indexed sender, uint256 amount);
    event NewwLANDReferral(
        address indexed sender,
        address referral,
        uint256 refAmount
    );
    event NewTicketReferral(
        address indexed sender,
        address referral,
        uint256 refAmount
    );
    event NewTicket(address indexed sender, uint256 ticketId, uint256 amount);
    event NewWithdrawwLand(address indexed sender, uint256 amount);
    event NewWithdrawTicket(address indexed sender, uint256 amount);

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsCombinator:INVALID_ROLE");
        _;
    }

    constructor(
        address _wLAND,
        address _busd,
        address _collectibles,
        address _dev,
        uint256[] memory _ticketsId,
        uint256[] memory _priceTickets
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
        setup(_wLAND, _busd, _collectibles, _dev, _ticketsId, _priceTickets);
    }

    function setup(
        address _wLAND,
        address _busd,
        address _collectibles,
        address _dev,
        uint256[] memory _ticketsId,
        uint256[] memory _priceTickets
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        wLAND = _wLAND;
        collectibles = _collectibles;
        busd = _busd;
        dev = _dev;
        for (uint256 i = 0; i < _ticketsId.length; i++) {
            priceTicket[_ticketsId[i]] = _priceTickets[i];
        }
    }

    function addRef(bytes32 ref, address account) public {
        require(referral[ref] == address(0), "APWarsLandSale:INVALID_REFERRAL");
        referral[ref] = account;
    }

    function buyTicket(
        uint256 ticketId,
        uint256 _amount,
        bytes32 _ref
    ) public {
        IERC1155 token = IERC1155(collectibles);

        require(
            priceTicket[ticketId] > 0,
            "APWarsLandSale:TICKET_INVALID_AMOUNT"
        );

        require(
            token.balanceOf(address(this), ticketId) >= _amount,
            "APWarsLandSale:TICKET_SOLD_OUT"
        );

        if (referral[_ref] != address(0)) {
            uint256 refAmount = priceTicket[ticketId]
                .mul(_amount)
                .mul(FIVE_PERCENT)
                .div(ONE_HUNDRED_PERCENT);
            uint256 netAmount = priceTicket[ticketId].mul(_amount).sub(
                refAmount
            );

            require(
                IERC20(wLAND).transferFrom(msg.sender, dev, netAmount),
                "APWarsLandSale:TICKET_INVALID_TRANSFER"
            );

            require(
                IERC20(wLAND).transferFrom(
                    msg.sender,
                    referral[_ref],
                    refAmount
                ),
                "APWarsLandSale:TICKET_INVALID_TRANSFER"
            );

            emit NewTicketReferral(msg.sender, referral[_ref], refAmount);
        } else {
            require(
                IERC20(wLAND).transferFrom(
                    msg.sender,
                    dev,
                    priceTicket[ticketId].mul(_amount)
                ),
                "APWarsLandSale:TICKET_INVALID_TRANSFER"
            );
        }

        token.safeTransferFrom(
            address(this),
            msg.sender,
            ticketId,
            _amount,
            DEFAULT_MESSAGE
        );

        wLANDTotalAmount.add(priceTicket[ticketId].mul(_amount));

        emit NewTicket(msg.sender, ticketId, _amount);
    }

    function buywLAND(uint256 _amount, bytes32 _ref) public {
    
        require(_amount > 0, "APWarsLandSale:INVALID_AMOUNT");

        IERC20 token = IERC20(wLAND);

        uint256 busdAmount = _amount.mul(PRICE_WLAND);
        uint256 amountWei = _amount.mul(10**18);

        require(
            token.balanceOf(address(this)) >= amountWei,
            "APWarsLandSale:INVALID_BALANCE"
        );

        if (referral[_ref] != address(0)) {
            uint256 refAmount = busdAmount.mul(FIVE_PERCENT).div(
                ONE_HUNDRED_PERCENT
            );
            uint256 netAmount = busdAmount.sub(refAmount);

            require(
                IERC20(busd).transferFrom(msg.sender, dev, netAmount),
                "APWarsLandSale:WLAND_INVALID_TRANSFER"
            );

            require(
                IERC20(busd).transferFrom(
                    msg.sender,
                    referral[_ref],
                    refAmount
                ),
                "APWarsLandSale:WLAND_INVALID_TRANSFER"
            );

            emit NewwLANDReferral(msg.sender, referral[_ref], refAmount);
        } else {
            require(
                IERC20(busd).transferFrom(msg.sender, dev, busdAmount),
                "APWarsLandSale:WLAND_INVALID_TRANSFER"
            );
        }

        token.transfer(msg.sender, amountWei);

        wLANDSoldAmount.add(amountWei);
        wLANDTotalAmount.add(amountWei);
        busdTotalAmount.add(busdAmount);

        emit NewSell(msg.sender, _amount);
    }

    function withdrawwLand() public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(wLAND);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);

        emit NewWithdrawwLand(msg.sender, amount);
    }

    function withdrawwLand(uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20 token = IERC20(wLAND);
        token.transfer(msg.sender, _amount);

        emit NewWithdrawwLand(msg.sender, _amount);
    }

    function withdrawTicket(uint256 _ticketId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC1155 token = IERC1155(collectibles);
        uint256 amount = token.balanceOf(address(this), _ticketId);

        token.safeTransferFrom(
            address(this),
            msg.sender,
            _ticketId,
            amount,
            DEFAULT_MESSAGE
        );

        emit NewWithdrawTicket(msg.sender, amount);
    }

    function withdrawTicket(uint256 _ticketId, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC1155 token = IERC1155(collectibles);

        token.safeTransferFrom(
            address(this),
            msg.sender,
            _ticketId,
            _amount,
            DEFAULT_MESSAGE
        );

        emit NewWithdrawTicket(msg.sender, _amount);
    }
}
