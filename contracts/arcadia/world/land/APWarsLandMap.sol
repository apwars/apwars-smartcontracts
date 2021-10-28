pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract APWarsLandMap is AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant LAND_TYPE_AT = keccak256("LAND_TYPE_AT");

    mapping(uint256 => uint256) private mapsLength;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))))
        private landAreas;
    mapping(uint256 => uint256) private maxResources;

    event NewLandAreas(
        address sender,
        uint256 landType,
        uint256 landMap,
        uint256[] x,
        uint256[] y,
        uint256[] types
    );

    event NewMaxResourceByArea(
        address sender,
        uint256[] types,
        uint256[] resources
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsWorldMap:INVALID_ROLE");
        _;
    }

    function setLandAreas(
        uint256 _landType,
        uint256 _landMap,
        uint256[] calldata _x,
        uint256[] calldata _y,
        uint256[] calldata _types
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _x.length == _y.length && _x.length == _types.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );

        if (mapsLength[_landType] < _landMap) {
            mapsLength[_landType] = _landMap;
        }

        for (uint256 i = 0; i < _x.length; i++) {
            landAreas[_landType][_landMap][_x[i]][_y[i]] = _types[i];
        }

        emit NewLandAreas(msg.sender, _landType, _landMap, _x, _y, _types);
    }

    function setMaxResourcesByType(
        uint256[] calldata _types,
        uint256[] calldata _resources
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _types.length == _resources.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );

        for (uint256 i = 0; i < _types.length; i++) {
            maxResources[_types[i]] = _resources[i];
        }

        emit NewMaxResourceByArea(msg.sender, _types, _resources);
    }

    function getMaxResourcesByType(uint256 _type)
        public
        view
        returns (uint256)
    {
        return maxResources[_type];
    }

    function randomMap(
        uint256 _worldId,
        uint256 _landType,
        uint256 _x,
        uint256 _y,
        uint256 _maxLength
    ) internal view returns (uint256) {
        bytes32 _structHash = keccak256(
            abi.encode(_worldId, _landType, _x, _y)
        );
        uint256 _randomNumber = uint256(_structHash);

        assembly {
            _randomNumber := add(mod(_randomNumber, _maxLength), 1)
        }

        return _randomNumber;
    }

    function getLandMap(
        uint256 _worldId,
        uint256 _landType,
        uint256 _x,
        uint256 _y
    ) public view returns (uint256) {
        return randomMap(_worldId, _landType, _x, _y, mapsLength[_landType]);
    }

    function getLandAreas(
        uint256 _landType,
        uint256 _map,
        uint256 _x,
        uint256 _y
    ) public view returns (uint256[] memory places) {
        places = new uint256[](_x * _y);

        uint256 index = 0;
        for (uint256 i = 0; i < _x; i++) {
            for (uint256 j = 0; j < _y; j++) {
                places[index] = landAreas[_landType][_map][i][j];
                index = index + 1;
            }
        }
    }
}
