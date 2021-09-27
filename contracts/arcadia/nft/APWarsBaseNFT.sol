pragma solidity >=0.6.0;

import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract APWarsBaseNFT is ERC721PresetMinterPauserAutoId {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    uint256 public lastId;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => bool) available;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsBaseNFT:INVALID_ROLE");
        _;
    }

    function setBaseURI(string memory _baseTokenURI)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        _setBaseURI(_baseTokenURI);
    }

    function getLastId() public view returns (uint256) {
        return lastId;
    }

    function isAvailable(uint256 _tokenId) public view returns (bool) {
        return available[_tokenId];
    }

    function getOwnerOf(uint256 _tokenId) public view returns (address) {
        if (isAvailable(_tokenId)) {
            return ownerOf(_tokenId);
        } else {
            return address(0);
        }
    }

    function mint(address to) public override onlyRole(MINTER_ROLE) {
        lastId = _tokenIds.current();

        _mint(to, lastId);
        _tokenIds.increment();

        available[lastId] = true;
    }
}
