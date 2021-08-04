// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract APWarsLandPrivateSale is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant VESTING = 9;
    uint256 private constant MAX_WORLD_TICKETS = 2;
    uint256 private constant MAX_CLAN_TICKETS = 50;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant DEV_PERCENTAGE = 10;

    uint256 public constant FIRST_PACKAGE_TARGET = 0;
    uint256 public constant SECOND_PACKAGE_TARGET = 500000 * 10**18;
    uint256 public constant THIRD_PACKAGE_TARGET = 1000000 * 10**18;
    uint256 public constant CLAN_TICKET_PRICE = 3900 * 10**18;
    uint256 public constant WORLD_TICKET_PRICE = 39000 * 10**18;
    uint256 public constant MAX_SUPPLY =
        FIRST_PACKAGE_TARGET + SECOND_PACKAGE_TARGET + THIRD_PACKAGE_TARGET;

    uint256 public constant FIRST_PACKAGE_PRICE = 5000;
    uint256 public constant SECOND_PACKAGE_PRICE = 7500;
    uint256 public constant THIRD_PACKAGE_PRICE = 15000;

    bytes private DEFAULT_MESSAGE;

    struct InvestedAmountInfo {
        uint256 investedAmount;
        uint256 wLANDAmount;
        uint256 remainingAmount;
        uint256 claimedAmount;
        uint256 nextBlock;
        uint256 claims;
        bool added;
    }

    uint256 public wLANDSoldAmount;
    mapping(address => bool) public whitelist;
    mapping(address => InvestedAmountInfo) public shares;
    address[] public buyers;
    address public collectibles;
    address public wLAND;
    address public busd;
    address public dev;
    uint256 public cliffStartBlock = 0;
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
    event NewWClanTicket(address indexed sender);
    event NewWorldTicketClaim(address indexed sender, uint256 amount);
    event NewClanTicketClaim(address indexed sender, uint256 amount);
    event NewClaim(
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
        address _busd,
        address _collectibles,
        uint256 _worldTicketId,
        uint256 _clanTicketId,
        address _dev,
        uint256 _cliffStartBlock,
        uint256 _vestingIntervalInBlocks
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());

        wLAND = _wLAND;
        collectibles = _collectibles;
        busd = _busd;
        dev = _dev;
        cliffStartBlock = _cliffStartBlock;
        vestingIntervalInBlocks = _vestingIntervalInBlocks;
        worldTicketId = _worldTicketId;
        clanTicketId = _clanTicketId;
    }

    function getBUSDwLANDPriceAmount(uint256 _wLANDSoldAmount, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 firstPackageAmount = 0;
        uint256 secondPackageAmount = 0;
        uint256 thirdPackageAmount = 0;

        uint256 level = _wLANDSoldAmount;
        uint256 remainingAmount = _amount;

        if (remainingAmount.add(level) > SECOND_PACKAGE_TARGET) {
            firstPackageAmount = SECOND_PACKAGE_TARGET.sub(level);
            remainingAmount = remainingAmount.sub(firstPackageAmount);
            level = level.add(firstPackageAmount);
        } else {
            firstPackageAmount = remainingAmount;
            remainingAmount = 0;
        }

        if (remainingAmount > 0) {
            if (remainingAmount.add(level) > THIRD_PACKAGE_TARGET) {
                secondPackageAmount = THIRD_PACKAGE_TARGET.sub(level);
                remainingAmount = remainingAmount.sub(secondPackageAmount);
                level = level.add(secondPackageAmount);
            } else {
                secondPackageAmount = remainingAmount;
                remainingAmount = 0;
            }

            thirdPackageAmount = remainingAmount;
        }

        return
            firstPackageAmount
                .mul(FIRST_PACKAGE_PRICE)
                .add(secondPackageAmount.mul(SECOND_PACKAGE_PRICE))
                .add(thirdPackageAmount.mul(THIRD_PACKAGE_PRICE))
                .div(ONE_HUNDRED_PERCENT);
    }

    function setupWhiteList(address[] calldata _whitelist, bool _value)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = _value;
        }
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
            block.number <= cliffStartBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
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
            block.number > cliffStartBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_NOT_ENDED"
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
            block.number <= cliffStartBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
        );

        worldTicketOwners[msg.sender] = worldTicketOwners[msg.sender].add(1);
        worldTicketsCount = worldTicketsCount.add(1);

        emit NewWorldTicket(msg.sender);
    }

    function claimWorldTicket() public {
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );
        require(
            block.number > cliffStartBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_NOT_ENDED"
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
        require(
            whitelist[msg.sender],
            "APWarsLandPrivateSale:SENDER_IS_NOT_WHITELISTED"
        );

        require(
            _amount.add(wLANDSoldAmount) < MAX_SUPPLY,
            "APWarsLandPrivateSale:MAX_SUPPLY"
        );

        require(
            block.number <= cliffStartBlock,
            "APWarsLandPrivateSale:PRIVATE_SALE_ENDED"
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
        shares[msg.sender].investedAmount = shares[msg.sender]
            .investedAmount
            .add(busdAmount);
        shares[msg.sender].nextBlock = cliffStartBlock;

        investedAmount = investedAmount.add(busdAmount);

        require(
            IERC20(busd).transferFrom(msg.sender, dev, busdAmount),
            "APWarsLandPrivateSale:FAIL_TO_PAY"
        );

        emit NewSell(msg.sender, _amount);
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

        IERC20(wLAND).transfer(msg.sender, amount);

        emit NewClaim(
            msg.sender,
            block.number,
            info.nextBlock,
            amount,
            info.remainingAmount
        );
    }
}
