// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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
