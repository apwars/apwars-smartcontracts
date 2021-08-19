// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IAPWarsMintableToken.sol";

//
contract APWarsLandPrivateSale is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant VESTING = 9;
    uint256 private constant MAX_WORLD_TICKETS = 2;
    uint256 private constant MAX_CLAN_TICKETS = 50;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant WWISDOW_RATIO = ONE_HUNDRED_PERCENT;

    uint256 public constant FIRST_PACKAGE_TARGET = 0;
    uint256 public constant SECOND_PACKAGE_TARGET = 500000 * 10**18;
    uint256 public constant THIRD_PACKAGE_TARGET = 1000000 * 10**18;
    uint256 public constant CLAN_TICKET_PRICE = 3999 * 10**18;
    uint256 public constant WORLD_TICKET_PRICE = 39999 * 10**18;
    uint256 public constant SOFT_CAP = 200000 * 10**18;
    uint256 public constant MAX_AVAILABLE_SUPPLY = 1462500 * 10**18;
    uint256 public constant MAX_SUPPLY = 1500000 * 10**18;

    uint256 public constant FIRST_PACKAGE_PRICE = 5000;
    uint256 public constant SECOND_PACKAGE_PRICE = 7500;
    uint256 public constant THIRD_PACKAGE_PRICE = 15000;

    bytes private DEFAULT_MESSAGE;

    struct InvestedAmountInfo {
        uint256 investedAmount;
        uint256 wLANDAmount;
        uint256 wWISDOWToClaim;
        uint256 remainingAmount;
        uint256 claimedAmount;
        uint256 nextBlock;
        uint256 claims;
        bool added;
    }

    uint256 public wLANDSoldAmount;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistAmount;
    mapping(address => bool) public whitelistPriority;
    mapping(address => InvestedAmountInfo) public shares;
    address[] public buyers;
    address public collectibles;
    address public wLAND;
    address public wWISDOW;
    address public busd;
    address public dev;
    uint256 public privateSaleEndBlock = 0;
    uint256 public cliffEndBlock = 0;
    uint256 public priorityEndBlock = 0;
    uint256 public worldTicketId = 0;
    uint256 public clanTicketId = 0;
    uint256 public nextBlockToClaim = 0;
    uint256 public vestingIntervalInBlocks = 0;
    uint256 public investedAmount = 0;
    mapping(address => uint256) public worldTicketOwners;
    mapping(address => bool) public worldTicketOwnersClaims;
    uint256 public worldTicketsCount;
    mapping(address => uint256) public clanTicketOwners;
    mapping(address => bool) public clanTicketOwnersClaims;
    uint256 public clanTicketsCount;

    event NewSell(address indexed sender, uint256 amount);
    event NewWorldTicket(address indexed sender);
    event NewwWISDOWClaim(address indexed sender, uint256 amount);
    event NewClanTicket(address indexed sender);
    event NewWorldTicketClaim(address indexed sender, uint256 amount);
    event NewClanTicketClaim(address indexed sender, uint256 amount);
    event RemainingAmountWithdrawn(address indexed sender, uint256 amount);
    event NewwLANDClaim(
        address indexed sender,
        uint256 block,
        uint256 unlockedBlock,
        uint256 amount,
        uint256 remainingAmount
    );

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsCombinator:INVALID_ROLE");
        _;
    }

    constructor(
        address _wLAND,
        address _wWISDOW,
        address _busd,
        address _collectibles,
        uint256 _worldTicketId,
        uint256 _clanTicketId,
        address _dev,
        uint256 _cliffEndBlock,
        uint256 _privateSaleEndBlock,
        uint256 _vestingIntervalInBlocks,
        uint256 _priorityEndBlock
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
        setup(
            _wLAND,
            _wWISDOW,
            _busd,
            _collectibles,
            _worldTicketId,
            _clanTicketId,
            _dev,
            _cliffEndBlock,
            _privateSaleEndBlock,
            _vestingIntervalInBlocks,
            _priorityEndBlock
        );
    }

    function setup (
        address _wLAND,
        address _wWISDOW,
        address _busd,
        address _collectibles,
        uint256 _worldTicketId,
        uint256 _clanTicketId,
        address _dev,
        uint256 _cliffEndBlock,
        uint256 _privateSaleEndBlock,
        uint256 _vestingIntervalInBlocks,
        uint256 _priorityEndBlock
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        wLAND = _wLAND;
        wWISDOW = _wWISDOW;
        collectibles = _collectibles;
        busd = _busd;
        dev = _dev;
        cliffEndBlock = _cliffEndBlock;
        privateSaleEndBlock = _privateSaleEndBlock;
        vestingIntervalInBlocks = _vestingIntervalInBlocks;
        worldTicketId = _worldTicketId;
        clanTicketId = _clanTicketId;
        priorityEndBlock = _priorityEndBlock;
    }

    function getAvailableAmounts(uint256 _wLANDSoldAmount)
        public
        view
        returns (uint256[3] memory availableAmounts)
    {
        uint256 level = 500000 * 10**18;
        availableAmounts[0] = level;
        availableAmounts[1] = level;
        availableAmounts[2] = MAX_AVAILABLE_SUPPLY.sub(level).sub(level);

        if (_wLANDSoldAmount >= level && _wLANDSoldAmount < level * 2) {
            availableAmounts[0] = 0;
            availableAmounts[1] = (level * 2).sub(_wLANDSoldAmount);
        } else if (_wLANDSoldAmount >= level * 2) {
            availableAmounts[0] = 0;
            availableAmounts[1] = 0;
            availableAmounts[2] = (level * 3).sub(_wLANDSoldAmount);
        } else {
            availableAmounts[0] = level.sub(_wLANDSoldAmount);
        }
    }

    function getAmountsByPackage(uint256 _wLANDSoldAmount, uint256 _amount)
        public
        view
        returns (uint256[3] memory amounts)
    {
        uint256[3] memory availableAmounts = getAvailableAmounts(
            _wLANDSoldAmount
        );

        uint256 remainingAmount = _amount;

        for (uint256 i = 0; i < 3; i++) {
            if (availableAmounts[i] > remainingAmount) {
                amounts[i] = remainingAmount;
                remainingAmount = 0;
            } else {
                amounts[i] = availableAmounts[i];
                remainingAmount = remainingAmount.sub(availableAmounts[i]);
            }
        }
    }

    function getBUSDwLANDPriceAmount(uint256 _wLANDSoldAmount, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256[3] memory amounts = getAmountsByPackage(
            _wLANDSoldAmount,
            _amount
        );

        return
            amounts[0]
                .mul(FIRST_PACKAGE_PRICE)
                .add(amounts[1].mul(SECOND_PACKAGE_PRICE))
                .add(amounts[2].mul(THIRD_PACKAGE_PRICE))
                .div(ONE_HUNDRED_PERCENT);
    }

    function setupWhitelist(
        address[] calldata _whitelist,
        uint256[] calldata _amount,
        bool _value
    ) public onlyRole(CONFIGURATOR_ROLE) {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = _value;
            whitelistAmount[_whitelist[i]] = _amount[i];
            whitelistPriority[_whitelist[i]] = _value;
        }
    }

    function checkWhitelist(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function buyClanTicket() public {
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );

        require(
            IERC20(busd).transferFrom(msg.sender, dev, CLAN_TICKET_PRICE),
            "APWarsLandPrivateSale:FAIL_TO_BUY_CLAN_TICKET"
        );

        require(
            block.number <= privateSaleEndBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
        );

        IERC1155 token = IERC1155(collectibles);

        require(
            token.balanceOf(address(this), clanTicketId) > worldTicketsCount,
            "APWarsLandPrivateSale:CLAN_TICKET_SOLD_OUT"
        );

        clanTicketOwners[msg.sender] = clanTicketOwners[msg.sender].add(1);
        clanTicketsCount = clanTicketsCount.add(1);

        emit NewWorldTicket(msg.sender);
    }

    function claimClanTicket() public {
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );
        require(
            block.number > cliffEndBlock,
            "APWarsLandPrivateSale:CLIFF_NOT_ENDED"
        );
        require(
            !clanTicketOwnersClaims[msg.sender],
            "APWarsLandPrivateSale:CLAIMED"
        );

        clanTicketOwnersClaims[msg.sender] = true;

        IERC1155(collectibles).safeTransferFrom(
            address(this),
            msg.sender,
            clanTicketId,
            clanTicketOwners[msg.sender],
            DEFAULT_MESSAGE
        );

        emit NewClanTicketClaim(msg.sender, clanTicketOwners[msg.sender]);
    }

    function buyWorldTicket() public {
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );

        require(
            IERC20(busd).transferFrom(msg.sender, dev, WORLD_TICKET_PRICE),
            "APWarsLandPrivateSale:FAIL_TO_BUY_WORLD_TICKET"
        );

        require(
            block.number <= privateSaleEndBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
        );

        IERC1155 token = IERC1155(collectibles);

        require(
            token.balanceOf(address(this), worldTicketId) > worldTicketsCount,
            "APWarsLandPrivateSale:WOLRD_TICKET_SOLD_OUT"
        );

        worldTicketOwners[msg.sender] = worldTicketOwners[msg.sender].add(1);
        worldTicketsCount = worldTicketsCount.add(1);

        emit NewWorldTicket(msg.sender);
    }

    function getAvailableWorldTickets() public view returns (uint256) {
        IERC1155 token = IERC1155(collectibles);
        return
            token.balanceOf(address(this), worldTicketId) >= worldTicketsCount
                ? token.balanceOf(address(this), worldTicketId).sub(
                    worldTicketsCount
                )
                : 0;
    }

    function getAvailableClanTickets() public view returns (uint256) {
        IERC1155 token = IERC1155(collectibles);
        return
            token.balanceOf(address(this), clanTicketId) >= worldTicketsCount
                ? token.balanceOf(address(this), clanTicketId).sub(
                    clanTicketsCount
                )
                : 0;
    }

    function claimWorldTicket() public {
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );
        require(
            block.number > cliffEndBlock,
            "APWarsLandPrivateSale:CLIFF_NOT_ENDED"
        );
        require(
            !worldTicketOwnersClaims[msg.sender],
            "APWarsLandPrivateSale:CLAIMED"
        );

        worldTicketOwnersClaims[msg.sender] = true;

        IERC1155(collectibles).safeTransferFrom(
            address(this),
            msg.sender,
            worldTicketId,
            worldTicketOwners[msg.sender],
            DEFAULT_MESSAGE
        );

        emit NewWorldTicketClaim(msg.sender, worldTicketOwners[msg.sender]);
    }

    function buywLAND(uint256 _amount) public {
        require(_amount > 0, "APWarsLandPrivateSale:INVALID_AMOUNT");

        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );

        require(
            _amount.add(wLANDSoldAmount) < MAX_AVAILABLE_SUPPLY,
            "APWarsLandPrivateSale:MAX_AVAILABLE_SUPPLY"
        );

        require(
            block.number <= privateSaleEndBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
        );

        require(
            (block.number <= priorityEndBlock &&
                whitelistAmount[msg.sender] == _amount &&
                whitelistPriority[msg.sender]) ||
                block.number > priorityEndBlock,
            "APWarsLandPrivateSale:PRIORITY_LEVEL"
        );

        uint256 busdAmount = getBUSDwLANDPriceAmount(wLANDSoldAmount, _amount);

        if (!shares[msg.sender].added) {
            buyers.push(msg.sender);
            shares[msg.sender].added = true;
        }

        shares[msg.sender].wLANDAmount = shares[msg.sender].wLANDAmount.add(
            _amount
        );
        shares[msg.sender].remainingAmount = shares[msg.sender].wLANDAmount;
        shares[msg.sender].wWISDOWToClaim = shares[msg.sender]
            .wWISDOWToClaim
            .add(_amount.div(WWISDOW_RATIO));
        shares[msg.sender].investedAmount = shares[msg.sender]
            .investedAmount
            .add(busdAmount);
        shares[msg.sender].nextBlock = cliffEndBlock;

        investedAmount = investedAmount.add(busdAmount);
        wLANDSoldAmount = wLANDSoldAmount.add(_amount);

        whitelistPriority[msg.sender] = false;

        require(
            IERC20(busd).transferFrom(msg.sender, dev, busdAmount),
            "APWarsLandPrivateSale:FAIL_TO_PAY"
        );

        emit NewSell(msg.sender, _amount);
    }

    function claimwWISDOW() public {
        InvestedAmountInfo storage info = shares[msg.sender];

        require(
            info.wWISDOWToClaim > 0,
            "APWarsLandPrivateSale:NOTHING_TO_CLAIM"
        );

        require(
            investedAmount >= SOFT_CAP,
            "APWarsLandPrivateSale:OPENED_SOFT_CAP"
        );

        uint256 amount = info.wWISDOWToClaim;
        IAPWarsMintableToken(wWISDOW).mint(msg.sender, amount);
        info.wWISDOWToClaim = 0;

        emit NewwWISDOWClaim(msg.sender, amount);
    }

    function claimwLAND() public {
        InvestedAmountInfo storage info = shares[msg.sender];

        require(
            info.remainingAmount > 0,
            "APWarsLandPrivateSale:NOTHING_TO_CLAIM"
        );

        require(
            info.nextBlock <= block.number,
            "APWarsLandPrivateSale:INVALID_BLOCK"
        );

        uint256 amount = info.wLANDAmount.div(VESTING);

        if (amount > info.remainingAmount) {
            amount = info.remainingAmount;
        }

        info.remainingAmount = info.remainingAmount.sub(amount);
        info.claimedAmount = info.claimedAmount.add(amount);
        info.nextBlock = info.nextBlock.add(vestingIntervalInBlocks);
        info.claims = info.claims.add(1);

        IERC20 token = IERC20(wLAND);

        if (amount > token.balanceOf(address(this))) {
            token.transfer(msg.sender, token.balanceOf(address(this)));
        } else {
            token.transfer(msg.sender, amount);
        }

        emit NewwLANDClaim(
            msg.sender,
            block.number,
            info.nextBlock,
            amount,
            info.remainingAmount
        );
    }

    function withdrawRemainingwLand() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            block.number > privateSaleEndBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_NOT_ENDED"
        );

        uint256 amount = MAX_SUPPLY.sub(wLANDSoldAmount);

        IERC20 token = IERC20(wLAND);

        if (amount > token.balanceOf(address(this))) {
            amount = token.balanceOf(address(this));
        }

        token.transfer(msg.sender, amount);

        emit RemainingAmountWithdrawn(msg.sender, amount);
    }
}
