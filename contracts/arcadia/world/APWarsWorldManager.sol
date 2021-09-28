pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../nft/APWarsBaseNFT.sol";
import "../nft/APWarsBaseNFTStorage.sol";
import "../inventory/APWarsTokenTransfer.sol";
import "../inventory/APWarsCollectiblesTransfer.sol";
import "./APWarsWorldTreasury.sol";
import "./APWarsWorldMap.sol";

contract APWarsWorldManager is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant LAND_X_Y_PREFIX = keccak256("LAND_");
    bytes32 public constant FOUNDATION_AT_PREFIX = keccak256("LAND_");
    bytes public DEFAULT_MESSAGE;

    APWarsWorldMap public worldMap;
    APWarsBaseNFT public worldNFT;
    APWarsBaseNFT public landNFT;
    APWarsBaseNFTStorage public nftStorage;
    APWarsTokenTransfer public tokenTransfer;
    APWarsCollectiblesTransfer public collectiblesTransfer;
    APWarsWorldTreasury worldTreasury;
    IERC20 public wLAND;
    ERC1155 public collectibles;
    mapping(uint256 => bool) public foundationsGameItemsMap;
    uint256[] public foundationsGameItems;
    address public deadAddress;

    struct LandPrice {
        uint256 currentPrice;
        uint256 nextPrice;
        uint256 nextBlockUpdate;
    }

    struct LandChangingType {
        uint256 worldId;
        uint256 x;
        uint256 y;
        uint256 newType;
        uint256 finishBlock;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public landIncrement;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public landTypeChangeInterval;
    mapping(uint256 => mapping(uint256 => LandPrice)) public landPrice;
    uint256 public priceChangeInterval;

    event NewRegion(
        address indexed sender,
        uint256 indexed worldId,
        uint256 region,
        uint256 count
    );

    event NewLand(
        address indexed sender,
        uint256 indexed worldId,
        uint256 x,
        uint256 y,
        uint256 price,
        uint256 tokenId
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsWorldManager:INVALID_ROLE");
        _;
    }

    function setup(
        APWarsWorldMap _worldMap,
        APWarsBaseNFT _worldNFT,
        APWarsBaseNFT _landNFT,
        APWarsBaseNFTStorage _nftStorage,
        uint256[] calldata _foundationsGameItems,
        address _deadAddress,
        APWarsTokenTransfer _tokenTransfer,
        IERC20 _wLAND,
        ERC1155 _collectibles,
        APWarsWorldTreasury _worldTreasury
    ) public onlyRole(CONFIGURATOR_ROLE) {
        worldMap = _worldMap;
        worldNFT = _worldNFT;
        landNFT = _landNFT;
        nftStorage = _nftStorage;
        deadAddress = _deadAddress;
        tokenTransfer = _tokenTransfer;
        wLAND = _wLAND;
        collectibles = _collectibles;
        worldTreasury = _worldTreasury;

        for (uint256 i = 0; i < foundationsGameItems.length; i++) {
            foundationsGameItemsMap[foundationsGameItems[i]] = false;
        }

        for (uint256 i = 0; i < _foundationsGameItems.length; i++) {
            foundationsGameItemsMap[_foundationsGameItems[i]] = true;
        }

        foundationsGameItems = _foundationsGameItems;
    }

    function setBasePrice(uint256 _worldId, uint256 _basePrice) public {
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        for (uint256 i = 1; i <= worldMap.getRegions(); i++) {
            landPrice[_worldId][i].currentPrice = _basePrice;
        }
    }

    function setPriceIncrementByFoundationType(
        uint256 _worldId,
        uint256[] calldata _types,
        uint256[] calldata _increments
    ) public {
        require(
            _types.length == _increments.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        for (uint256 i = 0; i < _types.length; i++) {
            landIncrement[_worldId][_types[i]] = _increments[i];
        }
    }

    function getPriceIncrementByFoundationType(
        uint256 _worldId,
        uint256 _type,
        uint256 _increment
    ) public view returns (uint256) {
        return landIncrement[_worldId][_type];
    }

    function setChangeTypeInterval(
        uint256 _worldId,
        uint256[] calldata _from,
        uint256[] calldata _to,
        uint256[] calldata _interval
    ) public {
        require(
            _from.length == _to.length && _from.length == _interval.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        for (uint256 i = 0; i < _from.length; i++) {
            landTypeChangeInterval[_worldId][_from[i]][_to[i]] = _interval[i];
        }
    }

    function getChangeTypeInterval(
        uint256 _worldId,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return landTypeChangeInterval[_worldId][_from][_to];
    }

    function getFoundationVarName(uint256 _x, uint256 _y)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(FOUNDATION_AT_PREFIX, _x, _y));
    }

    function getFoundationTypeByLand(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public view returns (uint256) {
        (, uint256 newValue, ) = nftStorage.getScheduledUInt256(
            address(worldNFT),
            _worldId,
            getFoundationVarName(_x, _y)
        );

        return newValue;
    }

    function getRawFoundationTypeByLand(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            nftStorage.getScheduledUInt256(
                address(worldNFT),
                _worldId,
                getFoundationVarName(_x, _y)
            );
    }

    function getFoundationsByLands(
        uint256 _worldId,
        uint256[] calldata _x,
        uint256[] calldata _y
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        require(
            _x.length == _y.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );

        uint256[] memory oldValues = new uint256[](_x.length);
        uint256[] memory newValues = new uint256[](_x.length);
        uint256[] memory blockLimits = new uint256[](_x.length);

        for (uint256 i = 0; i < _x.length; i++) {
            (
                oldValues[i],
                newValues[i],
                blockLimits[i]
            ) = getRawFoundationTypeByLand(_worldId, _x[i], _y[i]);
        }

        return (oldValues, newValues, blockLimits);
    }

    function getLandVarName(uint256 _x, uint256 _y)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(LAND_X_Y_PREFIX, _x, _y));
    }

    function getLandTokenId(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public view returns (uint256) {
        return
            nftStorage.getUInt256(
                address(worldNFT),
                _worldId,
                getLandVarName(_x, _y)
            );
    }

    function getLandOwner(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public view returns (address) {
        return landNFT.getOwnerOf(getLandTokenId(_worldId, _x, _y));
    }

    function getLandPrice(uint256 _worldId, uint256 _region)
        public
        view
        returns (uint256 currentPrice)
    {
        LandPrice storage price = landPrice[_worldId][_region];
        currentPrice = price.currentPrice;

        if (price.nextBlockUpdate > block.number) {
            currentPrice = price.nextPrice;
        }
    }

    function setLandTokenId(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _tokenId
    ) internal {
        nftStorage.setUInt256(
            address(worldNFT),
            _worldId,
            getLandVarName(_x, _y),
            _tokenId,
            0
        );
    }

    function buyLand(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public {
        require(
            worldMap.isValidLand(_x, _y),
            "APWarsWorldManager:INVALID_LAND"
        );
        require(
            getLandOwner(_worldId, _x, _y) == address(0),
            "APWarsWorldManager:LAND_IS_OWNED"
        );

        uint256 region = worldMap.getLandRegion(_x, _y);
        LandPrice storage price = landPrice[_worldId][region];

        if (price.nextBlockUpdate < block.number) {
            price.nextPrice = price.nextPrice.add(landIncrement[_worldId][0]);
        } else {
            price.currentPrice = price.nextPrice;
            price.nextBlockUpdate = block.number.add(priceChangeInterval);
        }

        tokenTransfer.transferFrom(
            wLAND,
            msg.sender,
            address(worldTreasury),
            price.currentPrice
        );

        landNFT.mint(msg.sender);
        uint256 tokenId = landNFT.getLastId();
        setLandTokenId(_worldId, _x, _y, tokenId);

        emit NewLand(msg.sender, _worldId, _x, _y, price.currentPrice, tokenId);
    }

    function setFoundationTypeByLand(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _type
    ) internal {
        nftStorage.setUInt256(
            address(worldNFT),
            _worldId,
            getLandVarName(_x, _y),
            _type,
            getChangeTypeInterval(
                _worldId,
                getFoundationTypeByLand(_worldId, _x, _y),
                _type
            )
        );
    }

    function buildFoundation(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) public {
        require(
            foundationsGameItemsMap[_foundationType],
            "APWarsWorldManager:INVALID_FOUNDATION_TYPE"
        );
        require(
            getLandOwner(_worldId, _x, _y) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );
        require(
            getFoundationTypeByLand(_worldId, _x, _y) == 0,
            "APWarsWorldManager:ALREADY_FOUNDED"
        );

        collectiblesTransfer.safeTransferFrom(
            collectibles,
            msg.sender,
            deadAddress,
            _foundationType,
            1,
            DEFAULT_MESSAGE
        );

        setFoundationTypeByLand(_worldId, _x, _y, _foundationType);
    }

    function destroyFoundation(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public {
        require(
            getLandOwner(_worldId, _x, _y) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );
        require(
            getFoundationTypeByLand(_worldId, _x, _y) != 0,
            "APWarsWorldManager:ALREADY_FOUNDED"
        );

        setFoundationTypeByLand(_worldId, _x, _y, 0);
    }
}
