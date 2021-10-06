pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../nft/APWarsBaseNFT.sol";
import "../nft/APWarsBaseNFTStorage.sol";
import "../inventory/APWarsTokenTransfer.sol";
import "../inventory/APWarsCollectiblesTransfer.sol";
import "./APWarsWorldMap.sol";
import "./IAPWarsWorldManagerEventHandler.sol";

contract APWarsWorldManager is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant LAND_X_Y_PREFIX = keccak256("LAND_X_Y_");
    bytes32 public constant FOUNDATION_AT_PREFIX = keccak256("FOUNDATION_X_Y_");

    uint256 public constant DEFAULT_FOUNDATION_TYPE = 1;

    bytes public DEFAULT_MESSAGE;

    APWarsWorldMap public worldMap;
    APWarsBaseNFT public worldNFT;
    APWarsBaseNFT public landNFT;
    APWarsBaseNFTStorage public nftStorage;
    APWarsTokenTransfer public tokenTransfer;
    APWarsCollectiblesTransfer public collectiblesTransfer;
    IAPWarsWorldManagerEventHandler eventHandler;
    IERC20 public wLAND;
    ERC1155 public collectibles;
    mapping(uint256 => bool) public foundationsGameItemsMap;
    uint256[] public foundationsGameItems;
    address public deadAddress;
    uint256 workerGameItemId;
    mapping(uint256 => uint256) basePrice;

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
        public foundationsBuildingTime;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public necessaryWorkersByFoundations;
    mapping(uint256 => mapping(uint256 => LandPrice)) private landPrice;
    mapping(uint256 => uint256) public priceChangeInterval;
    mapping(uint256 => address) private worldTreasury;

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

    event NewLandPrice(
        address indexed sender,
        uint256 indexed worldId,
        uint256 x,
        uint256 y,
        uint256 foundationType,
        uint256 currentPrice,
        uint256 newPrice,
        uint256 targetBlock
    );

    event NewPriceIncrement(
        address indexed sender,
        uint256 indexed worldId,
        uint256[] types,
        uint256[] increments
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
        uint256 _workerGameItemId,
        address _deadAddress,
        APWarsTokenTransfer _tokenTransfer,
        APWarsCollectiblesTransfer _collectiblesTransfer,
        IERC20 _wLAND,
        ERC1155 _collectibles,
        IAPWarsWorldManagerEventHandler _eventHandler
    ) public onlyRole(CONFIGURATOR_ROLE) {
        worldMap = _worldMap;
        worldNFT = _worldNFT;
        landNFT = _landNFT;
        nftStorage = _nftStorage;
        deadAddress = _deadAddress;
        tokenTransfer = _tokenTransfer;
        wLAND = _wLAND;
        collectibles = _collectibles;
        collectiblesTransfer = _collectiblesTransfer;
        workerGameItemId = _workerGameItemId;
        eventHandler = _eventHandler;

        for (uint256 i = 0; i < foundationsGameItems.length; i++) {
            foundationsGameItemsMap[foundationsGameItems[i]] = false;
        }

        for (uint256 i = 0; i < _foundationsGameItems.length; i++) {
            foundationsGameItemsMap[_foundationsGameItems[i]] = true;
        }

        foundationsGameItems = _foundationsGameItems;
    }

    function initializeWorldLandPricing(uint256 _worldId, uint256 _basePrice)
        public
    {
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        basePrice[_worldId] = _basePrice;
    }

    function setWorldTreasury(uint256 _worldId, address _address)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        worldTreasury[_worldId] = _address;
    }

    function getWorldTreasury(uint256 _worldId) public returns (address) {
        return worldTreasury[_worldId];
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

        emit NewPriceIncrement(msg.sender, _worldId, _types, _increments);
    }

    function getPriceIncrementByFoundationType(uint256 _worldId, uint256 _type)
        public
        view
        returns (uint256)
    {
        return landIncrement[_worldId][_type];
    }

    function setFoundationBuildingInterval(
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
            foundationsBuildingTime[_worldId][_from[i]][_to[i]] = _interval[i];
        }
    }

    function getFoundationBuildingInterval(
        uint256 _worldId,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return foundationsBuildingTime[_worldId][_from][_to];
    }

    function setNecessaryWorkersByFoundation(
        uint256 _worldId,
        uint256[] calldata _from,
        uint256[] calldata _to,
        uint256[] calldata _workers
    ) public {
        require(
            _from.length == _to.length && _from.length == _workers.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        for (uint256 i = 0; i < _from.length; i++) {
            necessaryWorkersByFoundations[_worldId][_from[i]][
                _to[i]
            ] = _workers[i];
        }
    }

    function getNecessaryWorkersByFoundation(
        uint256 _worldId,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return necessaryWorkersByFoundations[_worldId][_from][_to];
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
            uint256 oldValue,
            uint256 newValue,
            uint256 targetBlock,
            uint256 landType,
            address owner
        )
    {
        (oldValue, newValue, targetBlock) = nftStorage.getScheduledUInt256(
            address(worldNFT),
            _worldId,
            getFoundationVarName(_x, _y)
        );

        landType = worldMap.getSpecialPlace(_x, _y);
        owner = getLandOwner(_worldId, _x, _y);
    }

    function getFoundationsByLands(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _area
    )
        public
        view
        returns (
            uint256[] memory oldValues,
            uint256[] memory newValues,
            uint256[] memory targetBlocks,
            uint256[] memory types,
            address[] memory owners
        )
    {
        oldValues = new uint256[](_area * _area);
        newValues = new uint256[](_area * _area);
        targetBlocks = new uint256[](_area * _area);
        types = new uint256[](_area * _area);
        owners = new address[](_area * _area);

        uint256 i = 0;
        for (uint256 x = 0; x < _area; x++) {
            for (uint256 y = 0; y < _area; y++) {
                (
                    oldValues[i],
                    newValues[i],
                    targetBlocks[i],
                    types[i],
                    owners[i]
                ) = getRawFoundationTypeByLand(_worldId, _x + x, _y + y);

                i++;
            }
        }
    }

    function getLandFoundationVarName(uint256 _x, uint256 _y)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(FOUNDATION_AT_PREFIX, _x, _y));
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

    function getLandPriceByRegion(uint256 _worldId, uint256 _region)
        public
        view
        returns (uint256 currentPrice)
    {
        LandPrice storage price = landPrice[_worldId][_region];
        currentPrice = price.currentPrice;

        if (price.nextBlockUpdate <= block.number) {
            currentPrice = price.nextPrice;
        }

        if (currentPrice == 0) {
            return basePrice[_worldId];
        }
    }

    function getLandPrice(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public view returns (uint256) {
        uint256 region = worldMap.getLandRegion(_x, _y);
        return getLandPriceByRegion(_worldId, region);
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

    function buyLandAndBuildFoundation(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) public {
        buyLand(_worldId, _x, _y);
        buildFoundation(_worldId, _x, _y, _foundationType);
    }

    function setPriceChangeInterval(uint256 _worldId, uint256 _newInterval)
        public
    {
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        priceChangeInterval[_worldId] = _newInterval;
    }

    function getPriceChangeInterval(uint256 _worldId)
        public
        view
        returns (uint256)
    {
        return priceChangeInterval[_worldId];
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
            getLandFoundationVarName(_x, _y),
            _type,
            getFoundationBuildingInterval(
                _worldId,
                getFoundationTypeByLand(_worldId, _x, _y),
                _type
            )
        );
    }

    function setRegionLancePrice(
        uint256 _worldId,
        uint256 _region,
        uint256 _price
    ) public {
        require(
            worldNFT.getOwnerOf(_worldId) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );

        LandPrice storage price = landPrice[_worldId][_region];

        uint256 currentPrice = price.currentPrice;

        price.currentPrice = price.nextPrice;
        price.nextPrice = _price;
        price.nextBlockUpdate = block.number;

        emit NewLandPrice(
            msg.sender,
            _worldId,
            0,
            0,
            0,
            currentPrice,
            _price,
            block.number
        );
    }

    function updateRegionLandPrice(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) internal {
        uint256 region = worldMap.getLandRegion(_x, _y);
        LandPrice storage price = landPrice[_worldId][region];
        uint256 currentPrice = getLandPrice(_worldId, _x, _y);

        if (price.nextBlockUpdate < block.number) {
            price.nextBlockUpdate = block.number.add(
                getPriceChangeInterval(_worldId)
            );
            price.currentPrice = currentPrice;
        }

        price.nextPrice = currentPrice.add(
            getPriceIncrementByFoundationType(_worldId, _foundationType)
        );

        emit NewLandPrice(
            msg.sender,
            _worldId,
            _x,
            _y,
            _foundationType,
            currentPrice,
            price.nextPrice,
            price.nextBlockUpdate
        );
    }

    function buyLand(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public {
        require(
            worldNFT.isAvailable(_worldId),
            "APWarsWorldManager:INVALID_WORLD"
        );
        require(
            worldMap.isValidLand(_x, _y),
            "APWarsWorldManager:INVALID_LAND"
        );
        require(
            getLandOwner(_worldId, _x, _y) == address(0),
            "APWarsWorldManager:LAND_IS_OWNED"
        );

        uint256 landPrice = getLandPrice(_worldId, _x, _y);

        require(
            wLAND.allowance(msg.sender, address(tokenTransfer)) >= landPrice,
            "APWarsWorldManager:INVALID_WLAND_ALLOWANCE"
        );

        require(
            wLAND.balanceOf(msg.sender) >= landPrice,
            "APWarsWorldManager:INVALID_WLAND_BALANCE"
        );

        tokenTransfer.transferFrom(
            wLAND,
            msg.sender,
            getWorldTreasury(_worldId),
            landPrice
        );

        updateRegionLandPrice(_worldId, _x, _y, DEFAULT_FOUNDATION_TYPE);

        landNFT.mint(msg.sender);
        uint256 tokenId = landNFT.getLastId();
        setLandTokenId(_worldId, _x, _y, tokenId);
        setFoundationTypeByLand(_worldId, _x, _y, DEFAULT_FOUNDATION_TYPE);

        eventHandler.onBuyLand(address(this), msg.sender, _worldId, _x, _y);

        emit NewLand(msg.sender, _worldId, _x, _y, landPrice, tokenId);
    }

    function buildFoundation(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) public {
        require(
            worldNFT.isAvailable(_worldId),
            "APWarsWorldManager:INVALID_WORLD"
        );
        require(
            foundationsGameItemsMap[_foundationType],
            "APWarsWorldManager:INVALID_FOUNDATION_TYPE"
        );
        require(
            getLandOwner(_worldId, _x, _y) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );
        require(
            getFoundationTypeByLand(_worldId, _x, _y) ==
                DEFAULT_FOUNDATION_TYPE,
            "APWarsWorldManager:ALREADY_FOUNDED"
        );

        require(
            collectibles.isApprovedForAll(
                msg.sender,
                address(collectiblesTransfer)
            ),
            "APWarsWorldManager:INVALID_COLLECTIBLES_ALLOWANCE"
        );

        uint256 necessaryWorkers = getNecessaryWorkersByFoundation(
            _worldId,
            DEFAULT_FOUNDATION_TYPE,
            _foundationType
        );

        if (necessaryWorkers > 0) {
            require(
                collectibles.balanceOf(msg.sender, workerGameItemId) >=
                    necessaryWorkers,
                "APWarsWorldManager:INVALID_WORKERS_BALANCE"
            );

            collectiblesTransfer.safeTransferFrom(
                collectibles,
                msg.sender,
                deadAddress,
                workerGameItemId,
                necessaryWorkers,
                DEFAULT_MESSAGE
            );
        }

        require(
            collectibles.balanceOf(msg.sender, _foundationType) >=
                necessaryWorkers,
            "APWarsWorldManager:INVALID_FOUNDATION_TICKET_BALANCE"
        );

        collectiblesTransfer.safeTransferFrom(
            collectibles,
            msg.sender,
            deadAddress,
            _foundationType,
            1,
            DEFAULT_MESSAGE
        );

        updateRegionLandPrice(_worldId, _x, _y, _foundationType);
        setFoundationTypeByLand(_worldId, _x, _y, _foundationType);

        eventHandler.onBuildFoundation(
            address(this),
            msg.sender,
            _worldId,
            _x,
            _y,
            _foundationType
        );
    }

    function destroyFoundation(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public {
        require(
            worldNFT.isAvailable(_worldId),
            "APWarsWorldManager:INVALID_WORLD"
        );
        require(
            getLandOwner(_worldId, _x, _y) == msg.sender,
            "APWarsWorldManager:INVALID_OWNER"
        );
        require(
            getFoundationTypeByLand(_worldId, _x, _y) != 0,
            "APWarsWorldManager:ALREADY_FOUNDED"
        );

        require(
            collectibles.isApprovedForAll(
                msg.sender,
                address(collectiblesTransfer)
            ),
            "APWarsWorldManager:INVALID_COLLECTIBLES_ALLOWANCE"
        );

        uint256 foundationType = getFoundationTypeByLand(_worldId, _x, _y);
        uint256 necessaryWorkers = getNecessaryWorkersByFoundation(
            _worldId,
            foundationType,
            1
        );

        if (necessaryWorkers > 0) {
            require(
                collectibles.balanceOf(msg.sender, workerGameItemId) >=
                    necessaryWorkers,
                "APWarsWorldManager:INVALID_WORKERS_BALANCE"
            );

            collectiblesTransfer.safeTransferFrom(
                collectibles,
                msg.sender,
                deadAddress,
                workerGameItemId,
                necessaryWorkers,
                DEFAULT_MESSAGE
            );
        }

        setFoundationTypeByLand(_worldId, _x, _y, DEFAULT_FOUNDATION_TYPE);

        eventHandler.onDestroyFoundation(
            address(this),
            msg.sender,
            _worldId,
            _x,
            _y,
            DEFAULT_FOUNDATION_TYPE
        );
    }
}
