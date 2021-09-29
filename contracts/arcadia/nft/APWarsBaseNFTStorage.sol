pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./APWarsBaseNFT.sol";

contract APWarsBaseNFTStorage is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    uint256 public lastId;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct ScheduledUInt256 {
        uint256 oldValue;
        uint256 blockLimit;
        uint256 newValue;
    }

    mapping(address => mapping(uint256 => mapping(bytes32 => bool)))
        public boolStorage;
    mapping(address => mapping(uint256 => mapping(bytes32 => string)))
        public stringStorage;
    mapping(address => mapping(uint256 => mapping(bytes32 => address)))
        public addressStorage;

    mapping(address => mapping(uint256 => mapping(bytes32 => ScheduledUInt256)))
        public uint256Storage;

    event NewValue(
        address sender,
        address nft,
        uint256 tokenId,
        bytes32 varName,
        uint256 value,
        uint256 blockLimit
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsBaseNFTStorage:INVALID_ROLE"
        );
        _;
    }

    function setUInt256(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        uint256 _value,
        uint256 _block
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            uint256Storage[_nft][_tokenId][_var].blockLimit <= block.number,
            "APWarsBaseNFTStorage:INVALID_BLOCK"
        );

        uint256Storage[_nft][_tokenId][_var].oldValue = uint256Storage[_nft][
            _tokenId
        ][_var].newValue;
        uint256Storage[_nft][_tokenId][_var].newValue = _value;
        uint256Storage[_nft][_tokenId][_var].blockLimit = block.number.add(
            _block
        );

        emit NewValue(
            msg.sender,
            _nft,
            _tokenId,
            _var,
            _value,
            uint256Storage[_nft][_tokenId][_var].blockLimit
        );
    }

    function getUInt256(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (uint256) {
        return
            uint256Storage[_nft][_tokenId][_var].blockLimit <= block.number
                ? uint256Storage[_nft][_tokenId][_var].newValue
                : uint256Storage[_nft][_tokenId][_var].oldValue;
    }

    function getScheduledUInt256(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    )
        public
        view
        returns (
            uint256 oldValue,
            uint256 newValue,
            uint256 blockLimit
        )
    {
        oldValue = uint256Storage[_nft][_tokenId][_var].newValue;
        newValue = uint256Storage[_nft][_tokenId][_var].newValue;
        blockLimit = uint256Storage[_nft][_tokenId][_var].blockLimit;
    }

    function setBool(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        bool _value
    ) public {
        boolStorage[_nft][_tokenId][_var] = _value;
    }

    function getBool(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (bool) {
        return boolStorage[_nft][_tokenId][_var];
    }

    function setString(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        string memory _value
    ) public {
        stringStorage[_nft][_tokenId][_var] = _value;
    }

    function getString(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (string memory) {
        return stringStorage[_nft][_tokenId][_var];
    }

    function setAddress(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        address _value
    ) public {
        addressStorage[_nft][_tokenId][_var] = _value;
    }

    function getAddress(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (address) {
        return addressStorage[_nft][_tokenId][_var];
    }
}
