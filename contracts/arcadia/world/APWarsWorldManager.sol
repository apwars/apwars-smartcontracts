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
    APWarsWorldTreasury worldTreasury;
    IERC20 public wLAND;
    ERC1155 public collectibles;
    mapping(uint256 => bool) public foundationsGameItemsMap;
    uint256[] public foundationsGameItems;
    address public deadAddress;
    uint256 workerGameItemId;

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
        uint256 _workerGameItemId,
        address _deadAddress,
        APWarsTokenTransfer _tokenTransfer,
        APWarsCollectiblesTransfer _collectiblesTransfer,
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
        collectiblesTransfer = _collectiblesTransfer;
        workerGameItemId = _workerGameItemId;

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

    function setNecessaryWorkersByFoundations(
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

    function getNecessaryWorkersByFoundations(
        uint256 _worldId,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return necessaryWorkersByFoundations[_worldId][_from][_to];
    }

    function getFoundationBuildingInterval(
        uint256 _worldId,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return foundationsBuildingTime[_worldId][_from][_to];
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
        uint256 _x,
        uint256 _y,
        uint256 _area
    )
        public
        view
        returns (
            uint256[] memory oldValues,
            uint256[] memory newValues,
            uint256[] memory blockLimits
        )
    {
        oldValues = new uint256[](_area * _area);
        newValues = new uint256[](_area * _area);
        blockLimits = new uint256[](_area * _area);

        uint256 i = 0;
        for (uint256 x = 0; x < _area; x++) {
            for (uint256 y = 0; y < _area; y++) {
                (
                    oldValues[i],
                    newValues[i],
                    blockLimits[i]
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

        if (price.nextBlockUpdate > block.number) {
            currentPrice = price.nextPrice;
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

        uint256 region = worldMap.getLandRegion(_x, _y);
        LandPrice storage price = landPrice[_worldId][region];

        if (price.nextBlockUpdate < block.number) {
            price.nextPrice = price.nextPrice.add(
                landIncrement[_worldId][DEFAULT_FOUNDATION_TYPE]
            );
        } else {
            price.currentPrice = price.nextPrice;
            price.nextBlockUpdate = block.number.add(priceChangeInterval);
        }

        require(
            wLAND.balanceOf(msg.sender) >= price.currentPrice,
            "APWarsWorldManager:INVALID_WLAND_BALANCE"
        );
        require(
            wLAND.allowance(msg.sender, address(tokenTransfer)) >=
                price.currentPrice,
            "APWarsWorldManager:INVALID_WLAND_ALLOWANCE"
        );

        tokenTransfer.transferFrom(
            wLAND,
            msg.sender,
            address(worldTreasury),
            price.currentPrice
        );

        landNFT.mint(msg.sender);
        uint256 tokenId = landNFT.getLastId();
        setLandTokenId(_worldId, _x, _y, tokenId);

        setFoundationTypeByLand(_worldId, _x, _y, DEFAULT_FOUNDATION_TYPE);

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
            getLandFoundationVarName(_x, _y),
            _type,
            getFoundationBuildingInterval(
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

        uint256 necessaryWorkers = getNecessaryWorkersByFoundations(
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

        setFoundationTypeByLand(_worldId, _x, _y, _foundationType);
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

        uint256 foundationType = getFoundationTypeByLand(_worldId, _x, _y);
        uint256 necessaryWorkers = getNecessaryWorkersByFoundations(
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
    }
}
