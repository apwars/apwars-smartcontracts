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

contract APWarsWorldMap is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant LAND_TYPE_AT = keccak256("LAND_TYPE_AT");

    APWarsBaseNFTStorage public nftStorage;

    mapping(uint256 => mapping(uint256 => uint256)) public regions;
    mapping(uint256 => bool) public isSet;
    uint256 public maxX;
    uint256 public maxY;
    uint256 public landsPerRegion;
    mapping(uint256 => mapping(uint256 => uint256)) specialPlaces;

    event NewRegion(address indexed sender, uint256 indexed region);
    event NewLand(
        address indexed sender,
        uint256 indexed region,
        uint256 x,
        uint256 y
    );
    event NewSpecialPlaces(
        address sender,
        uint256[] x,
        uint256[] y,
        uint256[] types
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsWorldMap:INVALID_ROLE");
        _;
    }

    function setup(
        APWarsBaseNFTStorage _nftStorage,
        uint256 _maxX,
        uint256 _maxY,
        uint256 _landsPerRegion
    ) public onlyRole(CONFIGURATOR_ROLE) {
        nftStorage = _nftStorage;
        maxX = _maxX;
        maxY = _maxY;
        landsPerRegion = _landsPerRegion;
    }

    function getRegions() public view returns (uint256) {
        return (maxX * maxY) / (landsPerRegion * landsPerRegion);
    }

    function setupMap(
        uint256 _region,
        uint256 _regionX,
        uint256 _regionY
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(!isSet[_region], "APWarsWorldMap:IS_SET");
        require(_regionX <= maxX, "APWarsWorldMap:INVALID_X");
        require(_regionY <= maxY, "APWarsWorldMap:INVALID_Y");

        for (uint256 x = 0; x < landsPerRegion; x++) {
            for (uint256 y = 0; y < landsPerRegion; y++) {
                regions[x + (_regionX * landsPerRegion)][
                    y + (_regionY * landsPerRegion)
                ] = _region;
            }
        }

        isSet[_region] = true;

        emit NewRegion(msg.sender, _region);
    }

    function checkIsSet(uint256 _region) public view returns (bool) {
        return isSet[_region];
    }

    function resetRegion(uint256 _region)
        public
        onlyRole(CONFIGURATOR_ROLE)
        returns (bool)
    {
        isSet[_region] = false;
    }

    function isValidLand(uint256 _x, uint256 _y) public view returns (bool) {
        return regions[_x][_y] != 0 && specialPlaces[_x][_y] == 0;
    }

    function setSpecialPlaces(
        uint256[] calldata _x,
        uint256[] calldata _y,
        uint256[] calldata _types
    ) public {
        require(
            _x.length == _y.length && _x.length == _types.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );

        for (uint256 i = 0; i < _x.length; i++) {
            specialPlaces[_x[i]][_y[i]] = _types[i];
        }

        emit NewSpecialPlaces(msg.sender, _x, _y, _types);
    }

    function getSpecialPlace(uint256 _x, uint256 _y)
        public
        view
        returns (uint256)
    {
        return specialPlaces[_x][_y];
    }

    function getLandRegion(uint256 _x, uint256 _y)
        public
        view
        returns (uint256)
    {
        return regions[_x][_y];
    }
}
