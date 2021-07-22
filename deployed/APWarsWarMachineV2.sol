// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/IAPWarsBaseToken.sol


pragma solidity >=0.6.0;


interface IAPWarsBaseToken is IBEP20 {
    function burn(uint256 _amount) external;

    function mint(address to, uint256 amount) external;
}

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol



pragma solidity >=0.6.0 <0.8.0;








/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/utils/IAPWarsBurnManager.sol


pragma solidity >=0.6.0;


interface IAPWarsBurnManager {
    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view returns (uint16);

    function getBurnedAmount(address _token) external view returns (uint256);

    function manageAmount(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external;

    function burn(address _token) external;
}

// File: contracts/nfts/APWarsCollectibles.sol


pragma solidity >=0.6.0;









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

// File: contracts/utils/APWarsBurnManagerV2.sol


pragma solidity >=0.6.0;






contract APWarsBurnManagerV2 is Ownable, IAPWarsBurnManager {
    uint16 private constant ONE_HUNDRED_PERCENT = 10000;
    uint16 private constant ONE_PERCENT = 100;
    IERC1155 private collectibles;
    mapping(address => uint256) private burnedAmount;
    address previousBurnManager;
    address devAddress;
    mapping(IBEP20 => bool) burnableToken;

    mapping(uint256 => uint16) goldSaverConfig;
    uint256[] goldSavers;

    mapping(address => mapping(uint256 => uint16)) burnSaverAmount;
    mapping(address => uint256[]) burnSavers;

    event Burned(
        address farmManager,
        address token,
        address player,
        uint256 pid,
        uint256 userAmount,
        uint256 burnAmount
    );

    event BurnSaverAmountChanged(address token, uint256 id, uint256 amount);

    event BurnedAll(address token, uint256 burnAmount);

    constructor(address _devAddress) {
        devAddress = _devAddress;
    }

    function setPreviousBurnManager(address _previousBurnManager)
        public
        onlyOwner
    {
        previousBurnManager = _previousBurnManager;
    }

    function getPreviousBurnManager() public view returns (address) {
        return previousBurnManager;
    }

    function setBurnableToken(IBEP20 _token, bool isBurnable) public onlyOwner {
        burnableToken[_token] = isBurnable;
    }

    function isBurnableToken(IBEP20 _token) public view returns (bool) {
        return burnableToken[_token];
    }

    function getPreviousBurnManagerAddress() public view returns (address) {
        return previousBurnManager;
    }

    function getDevAddress() public view returns (address) {
        return devAddress;
    }

    function checkIfBurnSaverIsConfigured(address _token, uint256 _id)
        public
        view
        returns (bool)
    {
        uint256[] storage savers = burnSavers[_token];

        for (uint256 i = 0; i < savers.length; i++) {
            if (savers[i] == _id) {
                return true;
            }
        }

        return false;
    }

    function setBurnSaverAmount(
        address _token,
        uint256 _id,
        uint16 _amount
    ) public onlyOwner {
        if (!checkIfBurnSaverIsConfigured(_token, _id)) {
            burnSavers[_token].push(_id);
        }

        burnSaverAmount[_token][_id] = _amount;

        emit BurnSaverAmountChanged(_token, _id, _amount);
    }

    function getBurnSaverAmountByIndex(address _token, uint256 _index)
        public
        view
        returns (uint16)
    {
        return burnSaverAmount[_token][burnSavers[_token][_index]];
    }

    function getBurnSaverAmount(address _token, uint256 _id)
        public
        view
        returns (uint16)
    {
        return burnSaverAmount[_token][_id];
    }

    function getPlayerBalanceOfByIndex(
        address _token,
        address _player,
        uint256 _index
    ) public view returns (uint256) {
        return collectibles.balanceOf(_player, burnSavers[_token][_index]);
    }

    function getPlayerBalanceOfById(address _player, uint256 _id)
        public
        view
        returns (uint256)
    {
        return collectibles.balanceOf(_player, _id);
    }

    function getCompundBurnSaverByPlayer(address _token, address _player)
        public
        view
        returns (uint16)
    {
        uint16 burnSaver = 0;
        for (uint256 i = 0; i < burnSavers[_token].length; i++) {
            if (getPlayerBalanceOfByIndex(_token, _player, i) > 0) {
                burnSaver += getBurnSaverAmountByIndex(_token, i);
            }
        }

        return burnSaver;
    }

    function getBurnedAmount(address _token)
        external
        view
        override
        returns (uint256)
    {
        return
            burnedAmount[_token] +
            (
                previousBurnManager != address(0)
                    ? IAPWarsBurnManager(previousBurnManager).getBurnedAmount(
                        _token
                    )
                    : 0
            );
    }

    function getBurnRate(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid
    ) external view override returns (uint16) {
        uint16 burnRate = ONE_HUNDRED_PERCENT;
        uint16 compoundBurnSaver = getCompundBurnSaverByPlayer(_token, _player);

        if (compoundBurnSaver > burnRate) {
            burnRate = 0;
        } else {
            burnRate -= compoundBurnSaver;
        }

        if (burnRate == ONE_HUNDRED_PERCENT) {
            return ONE_HUNDRED_PERCENT - ONE_PERCENT;
        } else {
            return burnRate;
        }
    }

    function manageAmount(
        address _farmManager,
        address _token,
        address _player,
        uint256 _pid,
        uint256 _userAmount,
        uint256 _burnAmount
    ) external override {
        IBEP20 token = IBEP20(_token);

        if (!isBurnableToken(token)) {
            token.transfer(devAddress, _burnAmount);
        } else {
            burn(_token);
        }
    }

    function setCollectibles(IERC1155 _collectitles) public onlyOwner {
        collectibles = _collectitles;
    }

    function getCollectibles() public view returns (IERC1155) {
        return collectibles;
    }

    function burn(address _token) public override {
        IAPWarsBaseToken token = IAPWarsBaseToken(_token);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);

        burnedAmount[_token] += amount;

        BurnedAll(_token, amount);
    }
}

// File: contracts/IAPWarsUnit.sol


pragma solidity >=0.6.0;


interface IAPWarsUnit is IAPWarsBaseToken {
    function getAttackPower() external returns (uint256);

    function getDefensePower() external returns (uint256);

    function getTroopImproveFactor() external returns (uint256);
}

// File: contracts/APWarsWarMachineV2.sol


pragma solidity >=0.6.0;








/**
 * @title The war simulator for APWars Finance.
 * @author Vulug
 * @notice A player will use this contract to send troops by depositing unit tokens and getting them back home by
 *         withdrawing the remaining amounts. The war simulator will randomly select the attacker and defender team,
 *         so the player doesn't know if the system will use each unit's attack or defense power. The war is divided
 *         into two rounds: the first is completed by computing the battle between the teams. After the first stage,
 *         the winner will fight against the Dragon to collect the gold from the Dragon's pocket. At this point. A random
 *         value will define how much gold the army will get from the Dragon and how many troops will die fighting against the Dragon.
 *         The Dragon will burn all remaining gold that troop can't bring home.
 * @dev See the docs to understand how the battle system works. It is not so hard, but be guided by examples is a better way.
 */
contract APWarsWarMachineV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum WarStage {FIRST_ROUND, SECOND_ROUND, FINISHED, CLOSED}

    uint256 private constant ONE = 10**18;
    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant ONE_PERCENT = 10**2;
    uint256 private constant TEN_PERCENT = 10**3;
    uint256 private constant FIVE_PERCENT = 10**3 / 2;
    uint256 private constant TEAM_A = 1;
    uint256 private constant TEAM_B = 2;


    mapping(uint256 => uint256) public initialAttackPower;
    mapping(uint256 => uint256) public initialDefensePower;

    mapping(uint256 => address[]) private allowedTeamTokenAddresses;

    mapping(address => mapping(address => uint256)) private depositsByPlayer;
    mapping(address => uint256) private depositsByToken;

    mapping(address => uint256) private teams;
    mapping(uint256 => uint256) private attackPower;
    mapping(uint256 => mapping(address => uint256))
        private attackPowerByAddress;
    mapping(uint256 => uint256) private defensePower;
    mapping(uint256 => mapping(address => uint256))
        private defensePowerByAddress;

    address private tokenPrize;
    address[] private players;
    mapping(address => bool) private playersMapping;

    APWarsCollectibles private collectibles;

    uint256 public emergencyWithdralInterval;

    /**
     * @notice War information.
     * @param name The war name.
     * @param finalAttackPower The final attack power.
     * @param finalDefensePower The final defense power.
     * @param percAttackerLosses The percentage of losses from the attacker team.
     * @param percDefenderLosses The percentage of losses from the defender team.
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param winner The winner team number.
     * @param attackerLuck The attacker luck.
     * @param defenderLuck The defender luck.
     * @param isBadLuck Sepecifies if it is a bad luck (negative luck).
     * @param attackerCasualty The attacker casualty.
     * @param defenderCasualty The defender casualty.
     */
    struct WarInfo {
        string name;
        uint256 finalAttackPower;
        uint256 finalDefensePower;
        uint256 percAttackerLosses;
        uint256 percDefenderLosses;
        uint256 attackerTeam;
        uint256 defenderTeam;
        uint256 winner;
        uint256 attackerLuck;
        uint256 defenderLuck;
        bool isBadLuck;
        uint256 attackerCasualty;
        uint256 defenderCasualty;
    }

    /**
     * @notice The first round war random parameters configuration.
     * @param randomTeamSource The random number used to define the attacker and defender.
     * @param attackerCasualty The attacker casualty pecentage.
     * @param defenderCasualty The defender casualty pecentage.
     * @param attackerLuck The luck pecentage.
     * @param defenderLuck The luck pecentage.
     * @param randomBadLuckSource The number used to defined if it is a bad luck (negative luck).
     */
    struct WarFirstRoundRandomParameters {
        uint256 randomTeamSource;
        uint256 attackerCasualty;
        uint256 defenderCasualty;
        uint256 attackerLuck;
        uint256 defenderLuck;
        uint256 randomBadLuckSource;
    }

    /**
     * @notice The second round war random parameters configuration.
     * @param unlockedPrize The percentual of the unlocked prize.
     * @param casualty The casualty in the second round.
     */
    struct WarSecondRoundRandomParameters {
        uint256 unlockedPrize;
        uint256 casualty;
    }

    /// @notice The war information.
    /// @dev See the WarInfo struct.
    WarInfo public war;

    /// @notice The external random source hash.
    bytes32 public externalRandomSourceHashes;

    /// @notice It stores the current stage per war.
    WarStage public warStage;

    /// @notice It stores the first round random parameters generated for a war.
    WarFirstRoundRandomParameters public warFirstRoundRandomParameters;

    /// @notice It stores the second round random parameters generated for a war.
    WarSecondRoundRandomParameters public secondRoundRandomParameters;

    /// @notice It stores the total prize.
    uint256 public totalPrize;

    /// @notice It stores the id of each elixir NFT.
    uint256[] public nfts;

    /// @notice It stores the user alread withdrawn a token.
    mapping(address => mapping(address => bool)) public withdrawn;

    /// @notice It stores the BurnManager address.
    APWarsBurnManagerV2 public burnManager;

    /**
     * @notice Fired when a user sends troops (token units) to war.
     * @param player The user address.
     * @param token The unit token address.
     * @param team The unit team.
     * @param amount The deposited amount.
     * @param attackPower The unit attack power.
     * @param newTeamAttackPower The team attack power after deposit.
     * @param newTeamDefensePower The team defense power after deposit.
     * @param belovedHaterImprovement The team defense power after deposit.
     */
    event NewDeposit(
        address indexed player,
        address indexed token,
        uint256 indexed team,
        uint256 amount,
        uint256 attackPower,
        uint256 defensePower,
        uint256 newTeamAttackPower,
        uint256 newTeamDefensePower,
        uint256 belovedHaterImprovement
    );

    /**
     * @notice Fired when the contract calculates the a new power for the teams.
     * @param initialAttackTeamPower The initial attacker power.
     * @param initialDefenseTeamPower The initial defense power.
     * @param attackerPowerIncrement The calculated attack increment.
     * @param defenderPowerIncrement The calculated defense increment.
     * @param isAttackerIncrementNegative Specifies if the increment is negative.
     * @param isDefenderIncrementNegative Specifies if the increment is negative.
     * @param newAttackPower The attack power after changes.
     * @param newDefensePower The defense power after changes.
     */
    event PowerChanged(
        uint256 initialAttackTeamPower,
        uint256 initialDefenseTeamPower,
        uint256 attackerPowerIncrement,
        uint256 defenderPowerIncrement,
        bool isAttackerIncrementNegative,
        bool isDefenderIncrementNegative,
        uint256 newAttackPower,
        uint256 newDefensePower
    );

    /**
     * @notice Fired when the contract calculates the team improvement.
     * @param team The improved team number.
     * @param initialAttackPower The initial attacker power.
     * @param initialDefensePower The initial defense power.
     * @param improvementAttackPower The calculated attack improvement.
     * @param improvementDefensePower The calculated defense improvement.
     * @param newAttackPower The attack power after improvement.
     * @param newDefensePower The defense power after improvement.
     */
    event TroopImprovement(
        uint256 indexed team,
        uint256 initialAttackPower,
        uint256 initialDefensePower,
        uint256 improvementAttackPower,
        uint256 improvementDefensePower,
        uint256 newAttackPower,
        uint256 newDefensePower
    );

    /**
     * @notice Fired when the contract calculates the first random parameters.
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param attackerCasualty The percentage of attacker casualty.
     * @param defenderCasualty The percentage of defender casualty.
     * @param attackerLuck The percentage of attacker luck.
     * @param defenderLuck The percentage of defender luck.
     * @param isBadLuck Specifies if is a bad luck (negative luck).
     */
    event FirstRoundRandomParameters(
        uint256 attackerTeam,
        uint256 defenderTeam,
        uint256 attackerCasualty,
        uint256 defenderCasualty,
        uint256 attackerLuck,
        uint256 defenderLuck,
        bool isBadLuck
    );

    /**
     * @notice Fired when the contract calculates the second round random parameters.
     * @param unlockedPrize The percentual of the unlocked prize.
     * @param casualty The casualty in the second round.
     */
    event SecondRoundRandomParameters(uint256 unlockedPrize, uint256 casualty);

    /**
     * @notice Fired when the contract calculates the team losses.
     * @param team The team number.
     * @param isAttacker Specifies if the team is the attacker.
     * @param initialPower Specifies the team's initial power.
     * @param power Specifies the team's final power.
     * @param otherTeamPower Specifies the other team's final power.
     * @param losses Specifies the losses percentage.
     */
    event TeamLosses(
        uint256 indexed team,
        bool indexed isAttacker,
        uint256 initialPower,
        uint256 power,
        uint256 otherTeamPower,
        uint256 losses
    );

    /**
     * @notice Fired when the contract owner finishes a round.
     * @param sender Transaction sender.
     * @param externalRandomSource The revealed external random source.
     * @param winner The winner team.
     */
    event RoundFinished(
        uint256 indexed round,
        address sender,
        bytes32 externalRandomSource,
        uint256 winner,
        uint256 winnerLosses
    );

    /**
     * @notice Fired when an user request to withdraw the amount after a war.
     * @param player The player address.
     * @param tokenAddress The unit token address.
     * @param deposit The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event Withdraw(
        address indexed player,
        address indexed tokenAddress,
        uint256 deposit,
        uint256 amountToBurn,
        uint256 amountToSave,
        uint256 burned,
        uint256 net
    );

    /**
     * @notice Fired when an user request to withdraw the prize after the second round of war.
     * @param player The player address.
     * @param tokenAddress The token prize address.
     * @param totalPower The team total power.
     * @param userTotalPower The user total power (to calculate the user share in the prize).
     * @param userShare The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event PrizeWithdraw(
        address indexed player,
        address indexed tokenAddress,
        uint256 totalPower,
        uint256 userTotalPower,
        uint256 userShare,
        uint256 burned,
        uint256 net
    );

    constructor() {
        emergencyWithdralInterval = block.timestamp + 15 days;
    }

    /**
     * @notice It configures a the war with addresses and initial values.
     * @param _tokenPrize The token prize address (wGOLD contract).
     * @param _burnManager The BurnManager address.
     * @param _teamA Team A token addresses.
     * @param _teamB Team B token addresses.
     * @param _collectibles Collectibles address.
     * @param _nfts NFTs ids. Indexes 0-2 are the exlixirs ID, index 3 the Arcane's Book Id and index 4 Beloved Hater.
     */
    function setup(
        IAPWarsBaseToken _tokenPrize,
        APWarsBurnManagerV2 _burnManager,
        IAPWarsUnit[] calldata _teamA,
        IAPWarsUnit[] calldata _teamB,
        APWarsCollectibles _collectibles,
        uint256[] calldata _nfts
    ) public onlyOwner {
        collectibles = _collectibles;
        burnManager = _burnManager;
        nfts = _nfts;

        tokenPrize = address(_tokenPrize);

        delete allowedTeamTokenAddresses[TEAM_A];
        delete allowedTeamTokenAddresses[TEAM_B];

        for (uint256 i = 0; i < _teamA.length; i++) {
            teams[address(_teamA[i])] = TEAM_A;
            allowedTeamTokenAddresses[TEAM_A].push(address(_teamA[i]));
        }

        for (uint256 i = 0; i < _teamB.length; i++) {
            teams[address(_teamB[i])] = TEAM_B;
            allowedTeamTokenAddresses[TEAM_B].push(address(_teamB[i]));
        }
    }

    /**
     * @notice It creates a new war and stores the hash of the external random source. It is a important value that will
     * be used to compute random numbers. When the contract owner finishes a war only the original value will be accepted
     * as the random source, it is useful to keep a fair game.
     * @param _name The war name.
     * @param _externalRandomSourceHash The has of the external random source.
     */
    function createWar(string calldata _name, bytes32 _externalRandomSourceHash)
        public
        onlyOwner
    {
        war = WarInfo(_name, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0);
        warStage = WarStage.FIRST_ROUND;
        externalRandomSourceHashes = _externalRandomSourceHash;
    }

    /**
     * @notice It returns the player address by index.
     * @return The player address.
     */
    function getPlayerAddress(uint256 index) public view returns (address) {
        return players[index];
    }

    /**
     * @notice It returns how many players joined the war.
     * @return The players length.
     */
    function getPlayerLength() public view returns (uint256) {
        return players.length;
    }

    /**
     * @notice The way to send troops to war is depositing unit tokens, each unit token has attack and defense power and by
     * depositing the user is inscreasing the team power. Both sides do not for if they will attack or defense, so the rigth way
     * to fish this war is send the maximum amount of troops!
     * This method needs to receive the approval from the unit token contract to transfer the specified amount.
     * If the war is in the second round only winners can send more troops to collect more gold.
     * @param _unit Unit token address.
     * @param _amount How many troops the user is sending to war.
     */
    function deposit(IAPWarsUnit _unit, uint256 _amount) public nonReentrant {
        address tokenAddress = address(_unit);

        //identifying if the token is part from the TEAM_A or TEAM_B;
        uint256 team = teams[tokenAddress];
        WarStage stage = warStage;

        require(stage == WarStage.FIRST_ROUND, "War:DEPOSIT_IS_BLOCKED");

        //transfering the amount to this contract and increase the user deposit amount
        _unit.transferFrom(msg.sender, address(this), _amount);
        depositsByPlayer[tokenAddress][msg.sender] = depositsByPlayer[
            tokenAddress
        ][msg.sender]
            .add(_amount);
        depositsByToken[tokenAddress] = depositsByToken[tokenAddress].add(
            _amount
        );

        //getting the total power (attack and defense)
        uint256 troopAttackPower = _unit.getAttackPower().mul(_amount);
        uint256 troopDefensePower = _unit.getDefensePower().mul(_amount);

        //if the user has the Beloved Hate NFT it will increase the attack power in 1%
        uint256 belovedHaterImprovement = 0;
        if (collectibles.balanceOf(msg.sender, nfts[4]) > 0) {
            belovedHaterImprovement = troopAttackPower.mul(ONE_PERCENT).div(
                ONE_HUNDRED_PERCENT
            );

            troopAttackPower = troopAttackPower.add(belovedHaterImprovement);
        }

        //updating attack and defense powers
        attackPowerByAddress[team][msg.sender] = attackPowerByAddress[team][msg.sender].add(troopAttackPower).add(troopDefensePower);
        attackPower[team] = attackPower[team].add(troopAttackPower).add(troopDefensePower);
        defensePowerByAddress[team][msg.sender] = defensePowerByAddress[team][msg.sender].add(troopAttackPower).add(troopDefensePower);
        defensePower[team] = defensePower[team].add(troopAttackPower).add(troopDefensePower);

        if (!playersMapping[msg.sender]) {
            playersMapping[msg.sender] = true;
            players.push(msg.sender);
        }

        emit NewDeposit(
            msg.sender,
            tokenAddress,
            team,
            _amount,
            troopAttackPower,
            troopDefensePower,
            attackPower[team],
            defensePower[team],
            belovedHaterImprovement
        );
    }

    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @dev See the docs to understand how it works. It is not so hard, but be guided by examples is a better way.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function _defineFirstRoundRandomParameters(bytes32 _externalRandomSource)
        internal
    {
        uint256 salt = 0;

        uint256 randomTeamSource =
            random(_externalRandomSource, salt, ONE_HUNDRED_PERCENT);
        bool isTeamA = randomTeamSource > ONE_HUNDRED_PERCENT / 2;

        war.attackerTeam = isTeamA ? TEAM_A : TEAM_B;
        war.defenderTeam = !isTeamA ? TEAM_A : TEAM_B;

        salt = salt.add(randomTeamSource);

        war.attackerCasualty = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 4
        );
        salt = salt.add(war.attackerCasualty);
        war.defenderCasualty = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 4
        );
        salt = salt.add(war.defenderCasualty);
        war.attackerLuck = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.attackerLuck);
        war.defenderLuck = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.defenderLuck);

        uint256 randomBadLuckSource =
            random(_externalRandomSource, salt, ONE_HUNDRED_PERCENT);

        war.isBadLuck = randomBadLuckSource > ONE_HUNDRED_PERCENT / 2;

        warFirstRoundRandomParameters = WarFirstRoundRandomParameters(
            randomTeamSource,
            war.attackerCasualty,
            war.defenderCasualty,
            war.attackerLuck,
            war.defenderLuck,
            randomBadLuckSource
        );

        emit FirstRoundRandomParameters(
            war.attackerTeam,
            war.defenderTeam,
            war.attackerCasualty,
            war.defenderCasualty,
            war.attackerLuck,
            war.defenderLuck,
            war.isBadLuck
        );
    }

    //TODO: refactor the code to reduce the amount of duplicated code.
    /**
     * @notice It calculates the troop improvement by analysing if a specified unit has a troop impact factor, which is a percentual by unit.
     */
    function _calculateTroopImprovement() internal {
        uint256 attackImprovement = 0;
        uint256 defenseImprovement = 0;

        initialAttackPower[TEAM_A] = attackPower[TEAM_A];
        initialDefensePower[TEAM_A] = defensePower[TEAM_A];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_A].length; i++) {
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_A][i]);
            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[TEAM_A] = attackPower[TEAM_A].add(attackImprovement);

                defenseImprovement = defensePower[TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                defensePower[TEAM_A] = defensePower[TEAM_A].add(defenseImprovement);
            }
        }

        emit TroopImprovement(
            TEAM_A,
            initialAttackPower[TEAM_A],
            initialDefensePower[TEAM_A],
            attackImprovement,
            defenseImprovement,
            attackPower[TEAM_A],
            defensePower[TEAM_A]
        );

        initialAttackPower[TEAM_B] = attackPower[TEAM_B];
        initialDefensePower[TEAM_B] = defensePower[TEAM_B];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_B].length; i++) {
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_B][i]);

            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[TEAM_B] = attackPower[TEAM_B].add(attackImprovement);

                defenseImprovement = defensePower[TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                defensePower[TEAM_B] = defensePower[TEAM_B].add(defenseImprovement);
            }
        }

        emit TroopImprovement(
            TEAM_B,
            initialAttackPower[TEAM_B],
            initialDefensePower[TEAM_B],
            attackImprovement,
            defenseImprovement,
            attackPower[TEAM_B],
            defensePower[TEAM_B]
        );
    }

    /**
     * @notice It calculates the luck of a team. The luck of a team is the same amount of badluck to another.
     *         This function uses the pre-calculated random luck percentual.
     */
    function _calculateLuckImpact() internal {
        uint256 initialAttackTeamPower = attackPower[war.attackerTeam];
        uint256 initialDefenseTeamPower = defensePower[war.defenderTeam];

        uint256 attackerPowerByLuck =
            initialAttackTeamPower.mul(war.attackerLuck).div(ONE_HUNDRED_PERCENT);
        uint256 defensePowerByLuck =
            initialDefenseTeamPower.mul(war.defenderLuck).div(ONE_HUNDRED_PERCENT);

        // the luck is in the attacker point of view
        if (war.isBadLuck) {
            war.finalAttackPower = initialAttackTeamPower - attackerPowerByLuck;
            war.finalDefensePower = initialDefenseTeamPower + defensePowerByLuck;
        } else {
            war.finalAttackPower = initialAttackTeamPower + attackerPowerByLuck;
            war.finalDefensePower = initialDefenseTeamPower - defensePowerByLuck;
        }

        emit PowerChanged(
            initialAttackTeamPower,
            initialDefenseTeamPower,
            attackerPowerByLuck,
            defensePowerByLuck,
            war.isBadLuck,
            !war.isBadLuck,
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    /**
     * @notice It calculates the morale from both sides.
     */
    function _calculateMoraleImpact() internal {
        uint256 initialAttackTeamPower = war.finalAttackPower;
        uint256 initialDefenseTeamPower = war.finalDefensePower;

        uint256 attackerMoraleImpactPerc =
            initialAttackTeamPower.mul(ONE_HUNDRED_PERCENT).div(
                initialDefenseTeamPower
            );
        uint256 defenseMoraleImpactPerc =
            initialDefenseTeamPower.mul(ONE_HUNDRED_PERCENT).div(
                initialAttackTeamPower
            );

        uint256 attackerMoraleImpact =
            initialAttackTeamPower
                .mul(attackerMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(TEN_PERCENT);
        uint256 defenseMoraleImpact =
            initialDefenseTeamPower
                .mul(defenseMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(TEN_PERCENT);

        // if the morale impact is greater than 100% it indicates that the team
        // has more power than other, so we will try to create a balance.
        if (attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT) {
            war.finalAttackPower = war.finalAttackPower.sub(
                attackerMoraleImpact
            );
            war.finalDefensePower = war.finalDefensePower.add(
                defenseMoraleImpact
            );
        } else {
            war.finalAttackPower = war.finalAttackPower.add(
                attackerMoraleImpact
            );
            war.finalDefensePower = war.finalDefensePower.sub(
                defenseMoraleImpact
            );
        }

        emit PowerChanged(
            initialAttackTeamPower,
            initialDefenseTeamPower,
            attackerMoraleImpactPerc,
            defenseMoraleImpactPerc,
            attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT,
            !(attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT),
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    /**
     * @notice It calculates the losses from the both sides. This function uses the pre-calculated random losses percentual.
     */
    function _calculateLosses() internal {
        if (war.finalAttackPower > war.finalDefensePower) {
            war.winner = war.attackerTeam;
        } else {
            war.winner = war.defenderTeam;
        }

        uint256 totalPower = war.finalAttackPower.add(war.finalDefensePower);

        if (war.finalAttackPower == 0) {
            war.percAttackerLosses = 0;
        } else {
            war.percAttackerLosses = war
                .finalAttackPower
                .mul(ONE_HUNDRED_PERCENT)
                .div(totalPower);

            war.percAttackerLosses = ONE_HUNDRED_PERCENT.sub(
                war.percAttackerLosses
            );

            war.percAttackerLosses = war.percAttackerLosses.add(war.attackerCasualty);

            if(war.percAttackerLosses >= ONE_HUNDRED_PERCENT) {
                war.percAttackerLosses = ONE_HUNDRED_PERCENT.sub(ONE_PERCENT);
            }
        }

        if (war.finalDefensePower == 0) {
            war.percDefenderLosses = 0;
        } else {
            war.percDefenderLosses = war
                .finalDefensePower
                .mul(ONE_HUNDRED_PERCENT)
                .div(totalPower);

            war.percDefenderLosses = ONE_HUNDRED_PERCENT.sub(
                war.percDefenderLosses
            );

            war.percDefenderLosses = war.percDefenderLosses.add(war.defenderCasualty);

            if(war.percDefenderLosses >= ONE_HUNDRED_PERCENT) {
                war.percDefenderLosses = ONE_HUNDRED_PERCENT.sub(ONE_PERCENT);
            }

        }

        emit TeamLosses(
            war.attackerTeam,
            true,
            attackPower[war.attackerTeam],
            war.finalAttackPower,
            totalPower,
            war.percAttackerLosses
        );

        emit TeamLosses(
            war.defenderTeam,
            false,
            defensePower[war.defenderTeam],
            war.finalDefensePower,
            totalPower,
            war.percDefenderLosses
        );
    }

    /**
     * @notice It finishes the first round of a war. All the random parameters will be computed by revealing the original
     * external random source. This function is a templated method pattern which calls other helper functions. At the end of
     * the execution the war is changed to second round and the survivors can figth to get the gold from the dragon.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishFirstRound(bytes32 _externalRandomSource) public onlyOwner {
        _calculateTroopImprovement();
        _defineFirstRoundRandomParameters(_externalRandomSource);
        _calculateLuckImpact();

        // if there is no other side there is no morale impact
        if (war.finalAttackPower > 0 && war.finalDefensePower > 0) {
            _calculateMoraleImpact();
        }
        _calculateLosses();

        warStage = WarStage.SECOND_ROUND;

        emit RoundFinished(
            1,
            msg.sender,
            _externalRandomSource,
            war.winner,
            war.winner == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses
        );
    }

    /**
     * @notice It finishes the first round of a war. All the random parameters will be computed by revealing the original
     * external random source. This function is a templated method pattern which calls other helper functions. At the end of
     * the execution the war is changed to second round and the survivors can figth to get the gold from the dragon.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishSecondRound(bytes32 _externalRandomSource) public onlyOwner {
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenPrize);

        secondRoundRandomParameters.unlockedPrize = random(
            _externalRandomSource,
            0,
            ONE_HUNDRED_PERCENT
        );
        secondRoundRandomParameters.casualty = random(
            _externalRandomSource,
            secondRoundRandomParameters.unlockedPrize,
            ONE_HUNDRED_PERCENT
        );

        warStage = WarStage.FINISHED;
        totalPrize = token.balanceOf(address(this));

        //calculating the new losses after the second round
        uint256 losses =
            war.winner == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;
        uint256 newLosses =
            losses
                .mul(secondRoundRandomParameters.casualty)
                .div(ONE_HUNDRED_PERCENT)
                .add(losses);

        if (newLosses > ONE_HUNDRED_PERCENT) {
            newLosses = ONE_HUNDRED_PERCENT;
        }

        if (war.winner == war.attackerTeam) {
            war.percAttackerLosses = newLosses;
        } else {
            war.percDefenderLosses = newLosses;
        }

        emit SecondRoundRandomParameters(
            secondRoundRandomParameters.unlockedPrize,
            secondRoundRandomParameters.casualty
        );
        emit RoundFinished(
            2,
            msg.sender,
            _externalRandomSource,
            war.winner,
            newLosses
        );
    }

    function getPlayerInfo(address[] calldata _tokenAddresses, address _player)
        public
        view
        returns (
            uint256 depositAmount,
            uint256 totalAttackPowerTeamA,
            uint256 totalAttackPowerTeamB,
            uint256 totalDefensePowerTeamA,
            uint256 totalDefensePowerTeamB
        )
    {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            depositAmount = depositAmount.add(
                depositsByPlayer[_tokenAddresses[i]][_player]
            );
        }

        totalAttackPowerTeamA = attackPowerByAddress[TEAM_A][_player];
        totalAttackPowerTeamB = attackPowerByAddress[TEAM_B][_player];
        totalDefensePowerTeamA = defensePowerByAddress[TEAM_A][_player];
        totalDefensePowerTeamB = defensePowerByAddress[TEAM_B][_player];
    }

    function getWarInfo(uint256 _team, address[] calldata _tokenAddresses)
        public
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalAttackPower,
            uint256 totalDefensePower,
            address warTokenPrize,
            APWarsCollectibles warCollectibles
        )
    {
        address tokenAddress = address(0);

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            totalDepositAmount = totalDepositAmount.add(
                depositsByToken[tokenAddress]
            );
        }

        totalAttackPower = attackPower[_team];
        totalDefensePower = defensePower[_team];
        warTokenPrize = tokenPrize;
        warCollectibles = collectibles;
    }

    /**
     * @notice It withdraws the remaining amount of a unit token after the war. This function get the troop back to home.
     * @param _unit Unit token address.
     */
    function withdraw(IAPWarsUnit _unit) public nonReentrant {
        address tokenAddress = address(_unit);

        require(address(_unit) != tokenPrize, "War:INVALID_TOKEN_ADDRESS");

        require(
            !withdrawn[msg.sender][address(_unit)],
            "War:ALREADY_WITHDRAWN"
        );

        require(
            teams[tokenAddress] == TEAM_A || teams[tokenAddress] == TEAM_B,
            "War:INVALID_TOKEN_ADDRESS"
        );
        require(
            warStage == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAW"
        );

        uint256 team = teams[tokenAddress];
        uint256 depositAmount = depositsByPlayer[tokenAddress][msg.sender];

        uint256 toBurnPerc =
            team == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;

        uint256 amountToSave = 0;

        if (_unit.getTroopImproveFactor() > 0) {
            if (collectibles.balanceOf(msg.sender, nfts[3]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        } else {
            if (collectibles.balanceOf(msg.sender, nfts[0]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, nfts[1]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT + FIVE_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, nfts[2]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        }

        uint256 originalToBurnPerc = toBurnPerc;

        if (amountToSave > toBurnPerc) {
            toBurnPerc = 0;
        } else {
            toBurnPerc = toBurnPerc.sub(amountToSave);
        }

        uint256 amountToBurn =
            depositAmount.mul(toBurnPerc).div(ONE_HUNDRED_PERCENT);
        uint256 net = depositAmount - amountToBurn;

        _unit.transfer(address(burnManager), amountToBurn);
        burnManager.burn(address(_unit));

        //avoinding rounding errors to the last user
        if (_unit.balanceOf(address(this)) < net) {
            _unit.transfer(msg.sender, _unit.balanceOf(address(this)));
        } else {
            _unit.transfer(msg.sender, net);
        }

        withdrawn[msg.sender][address(_unit)] = true;

        emit Withdraw(
            msg.sender,
            tokenAddress,
            depositAmount,
            originalToBurnPerc,
            amountToSave,
            amountToBurn,
            net
        );
    }

    /**
     * @notice It returns the total prize locked when the war was finished or the current balance if the war is running.
     */
    function getTotalPrize() public view returns (uint256) {
        return
            totalPrize == 0
                ? IAPWarsBaseToken(tokenPrize).balanceOf(address(this))
                : totalPrize;
    }

    //TODO: Check if the user can run this method
    /**
     * @notice It withdraws the unlocked prize and burns the locked prize for each user.
     *         The total prize is the token prize total balance when the war is finisehd.
     *         The user share corresponds to the proportion of user total power and the the team
     *         total power.
     */
    function withdrawPrize() public nonReentrant {
        address tokenAddress = tokenPrize;
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenAddress);

        require(
            !withdrawn[msg.sender][address(tokenAddress)],
            "War:ALREADY_WITHDRAWN"
        );

        require(
            warStage == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAL_PRIZE"
        );

        bool isAttacker = war.attackerTeam == war.winner;
        uint256 teamTotalPower =
            isAttacker ? initialAttackPower[war.winner] : initialDefensePower[war.winner];
        uint256 userTotalPower =
            isAttacker
                ? attackPowerByAddress[war.winner][msg.sender]
                : defensePowerByAddress[war.winner][msg.sender];

        uint256 userShare =
            userTotalPower.mul(ONE_HUNDRED_PERCENT).div(teamTotalPower);
        uint256 userPrize = totalPrize.mul(userShare).div(ONE_HUNDRED_PERCENT);
        uint256 amountToBurn =
            userPrize
                .mul(
                ONE_HUNDRED_PERCENT.sub(
                    secondRoundRandomParameters.unlockedPrize
                )
            )
                .div(ONE_HUNDRED_PERCENT);
        uint256 net = userPrize - amountToBurn;

        token.transfer(address(burnManager), amountToBurn);
        burnManager.burn(address(token));

        //avoinding rounding errors to the last user
        if (token.balanceOf(address(this)) < net) {
            token.transfer(msg.sender, token.balanceOf(address(this)));
        } else {
            token.transfer(msg.sender, net);
        }

        withdrawn[msg.sender][address(tokenAddress)] = true;

        emit PrizeWithdraw(
            msg.sender,
            tokenAddress,
            teamTotalPower,
            userTotalPower,
            userShare,
            amountToBurn,
            net
        );
    }

    function emergencyWithdraw(IAPWarsBaseToken _token, uint256 _amount)
        public
        onlyOwner
    {
        require(
            block.timestamp > emergencyWithdralInterval,
            "War:NOT_ALLOWED_YET"
        );

        _token.transfer(msg.sender, _amount);
    }

    /**
     * @notice It returns the hash of a bytes32 parameters. Used to help users to configure a new war.
     * @param externalRandomSource A bytes32 external source to generate random numbers. This value will be combined with
     * others random data from the current state of the blockchain.
     */
    function hashExternalRandomSource(bytes32 externalRandomSource)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(externalRandomSource));
    }

    /**
     * @notice It generates a pseudo random numbers based on a external random source defined when the war was created.
     * @dev The externalRandomSource parameter is the original value. The hash of this value must be set when
     *      the war is created. To help this process you can user the hashExternalRandomSource function. It is a public
     *      function to help aditors verify the generated random numbers at the end of a war stage.
     * @param _externalRandomSource The original external random source.
     * @param _salt A salt to generate random numbers using the same external random source.
     * @param _maxNumber The max number to be generated, used to create a range of random number.
     * @return Then computed pseudo random number.
     */
    function random(
        bytes32 _externalRandomSource,
        uint256 _salt,
        uint256 _maxNumber
    ) public view returns (uint256) {
        bytes32 hash = hashExternalRandomSource(_externalRandomSource);

        require(
            hash == externalRandomSourceHashes,
            "War:INVALID_EXTERNAL_RANDOM_SOURCE"
        );

        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        bytes32 _structHash =
            keccak256(
                abi.encode(_blockhash, gasLeft, _salt, _externalRandomSource)
            );
        uint256 _randomNumber = uint256(_structHash);

        assembly {
            _randomNumber := add(mod(_randomNumber, _maxNumber), 1)
        }

        return _randomNumber;
    }
}
