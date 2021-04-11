// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../IAPWarsBaseToken.sol";
import "../utils/IAPWarsBurnManager.sol";

contract APWarsCollectibles is
    ERC1155Receiver,
    ERC1155,
    ERC1155Burnable,
    ERC1155Pausable,
    AccessControl
{
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    uint256 DEV_FEE = 10;
    address private devAddress;
    mapping(bytes => mapping(address => bool)) claims;
    mapping(uint256 => uint256) totalSupply;
    mapping(uint256 => uint256) maxSupply;
    mapping(uint256 => bool) isMinted;
    mapping(uint256 => bool) multipleClaimsForbidden;

    IAPWarsBurnManager private burnManager;

    constructor(IAPWarsBurnManager _burnManager, string memory uri)
        ERC1155(uri)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(VALIDATOR_ROLE, _msgSender());

        burnManager = _burnManager;
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsCollectibles: INVALID_ROLE"
        );
        _;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function mint(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyRole(MINTER_ROLE) {
        require(!isMinted[_id], "APWarsCollectibles:ALREADY_MINTED");

        _mint(_account, _id, _amount, _data);
        totalSupply[_id] = _amount;
        isMinted[_id] = true;
    }

    function hashClaim(
        address _address,
        uint256 _id,
        uint256 _price
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _id, _price));
    }

    function getTotalSupply(uint256 _id) public returns (uint256) {
        return totalSupply[_id];
    }

    function getMaxSupply(uint256 _id) public returns (uint256) {
        return maxSupply[_id];
    }

    function getMultipleClaimsForbidden(uint256 _id) public returns (bool) {
        return multipleClaimsForbidden[_id];
    }

    function setMultipleClaimsForbidden(uint256 _id, bool _value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        multipleClaimsForbidden[_id] = _value;
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(maxSupply[_id] == 0, "APWarsCollectibles:setMaxSupply");
        maxSupply[_id] = _maxSupply;
    }

    function setBurnManager(IAPWarsBurnManager _burnManager)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        burnManager = _burnManager;
    }

    function getBurnManager() public view returns (IAPWarsBurnManager) {
        return burnManager;
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            return ecrecover(prefixedHash, v, r, s);
        }
    }

    function claim(
        IAPWarsBaseToken _token,
        uint256 _id,
        uint256 _price,
        bytes memory _signature
    ) public {
        require(
            totalSupply[_id] < maxSupply[_id],
            "APWarsCollectibles:FORBIDDEN"
        );
        require(
            !claims[_signature][msg.sender] ||
                (claims[_signature][msg.sender] &&
                    !multipleClaimsForbidden[_id]),
            "APWarsCollectibles:ALREADY_CLAIMED"
        );

        bytes32 hash = hashClaim(address(_token), _id, _price);
        address validator = recover(hash, _signature);

        require(
            validator != address(0),
            "APWarsCollectibles:INVALID_SIGNATURE"
        );
        require(
            hasRole(VALIDATOR_ROLE, validator),
            "APWarsCollectibles:INVALID_VALIDATOR"
        );

        uint256 amount = 1;

        uint256 fee = _price.div(DEV_FEE);
        uint256 netAmount = _price.sub(fee);
        _token.transferFrom(msg.sender, devAddress, fee);
        _token.transferFrom(msg.sender, address(burnManager), netAmount);
        burnManager.burn(address(_token));

        super._mint(msg.sender, _id, amount, _signature);

        totalSupply[_id] = totalSupply[_id].add(amount);
        claims[_signature][msg.sender] = true;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Pausable) {}

    function getDevAddress() public returns (address) {
        return devAddress;
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        devAddress = _devAddress;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }
}
