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
        uint256 newValue;
        uint256 targetBlock;
    }

    struct ScheduledString {
        string oldValue;
        string newValue;
        uint256 targetBlock;
    }

    struct ScheduledBytes32 {
        bytes32 oldValue;
        bytes32 newValue;
        uint256 targetBlock;
    }

    mapping(address => mapping(uint256 => mapping(bytes32 => ScheduledString)))
        public stringStorage;
    mapping(address => mapping(uint256 => mapping(bytes32 => ScheduledBytes32)))
        public bytes32Storage;

    mapping(address => mapping(uint256 => mapping(bytes32 => ScheduledUInt256)))
        public uint256Storage;

    event NewUInt256Value(
        address sender,
        address nft,
        uint256 tokenId,
        bytes32 varName,
        uint256 oldValue,
        uint256 newValue,
        uint256 targetBlock
    );

    event NewStringValue(
        address sender,
        address nft,
        uint256 tokenId,
        bytes32 varName,
        string oldValue,
        string newValue,
        uint256 targetBlock
    );

    event NewBytes32Value(
        address sender,
        address nft,
        uint256 tokenId,
        bytes32 varName,
        bytes32 oldValue,
        bytes32 newValue,
        uint256 targetBlock
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
            uint256Storage[_nft][_tokenId][_var].targetBlock <= block.number,
            "APWarsBaseNFTStorage:INVALID_BLOCK"
        );

        uint256Storage[_nft][_tokenId][_var].oldValue = uint256Storage[_nft][
            _tokenId
        ][_var].newValue;
        uint256Storage[_nft][_tokenId][_var].newValue = _value;
        uint256Storage[_nft][_tokenId][_var].targetBlock = block.number.add(
            _block
        );

        emit NewUInt256Value(
            msg.sender,
            _nft,
            _tokenId,
            _var,
            uint256Storage[_nft][_tokenId][_var].oldValue,
            uint256Storage[_nft][_tokenId][_var].newValue,
            uint256Storage[_nft][_tokenId][_var].targetBlock
        );
    }

    function setString(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        string calldata _value,
        uint256 _block
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            stringStorage[_nft][_tokenId][_var].targetBlock <= block.number,
            "APWarsBaseNFTStorage:INVALID_BLOCK"
        );

        stringStorage[_nft][_tokenId][_var].oldValue = stringStorage[_nft][
            _tokenId
        ][_var].newValue;
        stringStorage[_nft][_tokenId][_var].newValue = _value;
        stringStorage[_nft][_tokenId][_var].targetBlock = block.number.add(
            _block
        );

        emit NewStringValue(
            msg.sender,
            _nft,
            _tokenId,
            _var,
            stringStorage[_nft][_tokenId][_var].oldValue,
            stringStorage[_nft][_tokenId][_var].newValue,
            stringStorage[_nft][_tokenId][_var].targetBlock
        );
    }

    function setBytes32(
        address _nft,
        uint256 _tokenId,
        bytes32 _var,
        bytes32 _value,
        uint256 _block
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            bytes32Storage[_nft][_tokenId][_var].targetBlock <= block.number,
            "APWarsBaseNFTStorage:INVALID_BLOCK"
        );

        bytes32Storage[_nft][_tokenId][_var].oldValue = bytes32Storage[_nft][
            _tokenId
        ][_var].newValue;
        bytes32Storage[_nft][_tokenId][_var].newValue = _value;
        bytes32Storage[_nft][_tokenId][_var].targetBlock = block.number.add(
            _block
        );

        emit NewBytes32Value(
            msg.sender,
            _nft,
            _tokenId,
            _var,
            bytes32Storage[_nft][_tokenId][_var].oldValue,
            bytes32Storage[_nft][_tokenId][_var].newValue,
            bytes32Storage[_nft][_tokenId][_var].targetBlock
        );
    }

    function getUInt256(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (uint256) {
        return
            uint256Storage[_nft][_tokenId][_var].targetBlock <= block.number
                ? uint256Storage[_nft][_tokenId][_var].newValue
                : uint256Storage[_nft][_tokenId][_var].oldValue;
    }

    function getString(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (string memory) {
        return
            stringStorage[_nft][_tokenId][_var].targetBlock <= block.number
                ? stringStorage[_nft][_tokenId][_var].newValue
                : stringStorage[_nft][_tokenId][_var].oldValue;
    }

    function getBytes32(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    ) public view returns (bytes32) {
        return
            bytes32Storage[_nft][_tokenId][_var].targetBlock <= block.number
                ? bytes32Storage[_nft][_tokenId][_var].newValue
                : bytes32Storage[_nft][_tokenId][_var].oldValue;
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
            uint256 targetBlock
        )
    {
        oldValue = uint256Storage[_nft][_tokenId][_var].oldValue;
        newValue = uint256Storage[_nft][_tokenId][_var].newValue;
        targetBlock = uint256Storage[_nft][_tokenId][_var].targetBlock;
    }

    function getScheduledString(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    )
        public
        view
        returns (
            string memory oldValue,
            string memory newValue,
            uint256 targetBlock
        )
    {
        oldValue = stringStorage[_nft][_tokenId][_var].oldValue;
        newValue = stringStorage[_nft][_tokenId][_var].newValue;
        targetBlock = stringStorage[_nft][_tokenId][_var].targetBlock;
    }

    function getScheduledBytes32(
        address _nft,
        uint256 _tokenId,
        bytes32 _var
    )
        public
        view
        returns (
            bytes32 oldValue,
            bytes32 newValue,
            uint256 targetBlock
        )
    {
        oldValue = bytes32Storage[_nft][_tokenId][_var].oldValue;
        newValue = bytes32Storage[_nft][_tokenId][_var].newValue;
        targetBlock = bytes32Storage[_nft][_tokenId][_var].targetBlock;
    }
}
