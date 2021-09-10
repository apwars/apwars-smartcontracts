// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../utils/IAPWarsBurnManager.sol";

import "./IAPWarsCombinatorManager.sol";
import "./IAPWarsMintableToken.sol";

contract APWarsCombinatorTokenGameItem is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant DEV_PERCENTAGE = 10;
    bytes private DEFAULT_MESSAGE;

    struct Claimable {
        uint256 combinatorId;
        uint256 startBlock;
        uint256 multiple;
    }

    mapping(uint256 => mapping(address => Claimable)) public combinators;
    mapping(uint256 => uint256) public combinatorsCount;
    address public feeAddress;
    address public burnManagerAddress;
    address public combinatorManagerAddress;

    event NewCombinator(
        address indexed sender,
        uint256 indexed combinatorId,
        uint256 multiple
    );

    event NewSetup(
        address feeAddress,
        address burnManagerAddress,
        address combinatorManagerAddress
    );

    event NewTokenClaim(address indexed sender, uint256 indexed combinatorId);

    event NewGameItemClaim(
        address indexed sender,
        uint256 indexed combinatorId
    );

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsCombinatorTokenGameItem:INVALID_ROLE"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    function setup(
        address _feeAddress,
        address _burnManagerAddress,
        address _combinatorManagerAddress
    ) public onlyRole(CONFIGURATOR_ROLE) {
        feeAddress = _feeAddress;
        burnManagerAddress = _burnManagerAddress;
        combinatorManagerAddress = _combinatorManagerAddress;

        emit NewSetup(
            _feeAddress,
            _burnManagerAddress,
            _combinatorManagerAddress
        );
    }

    function combineTokens(uint256 _combinatorId, uint256 _multiple) public {
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );
        (, uint256 maxMultiple, bool isEnabled) = manager
            .getGeneralConfig(msg.sender, address(this), _combinatorId);

        require(isEnabled, "APWarsCombinatorTokenGameItem:DISABLED_COMBINATOR");

        require(
            combinators[_combinatorId][msg.sender].combinatorId == 0,
            "APWarsCombinatorTokenGameItem:COMBINATOR_IS_EXCLUSIVE"
        );

        require(
            _multiple > 0 && _multiple <= maxMultiple,
            "APWarsCombinatorTokenGameItem:INVALID_MULTIPLE"
        );

        _processStake(_combinatorId, _multiple);

        _processTokensTransfers(msg.sender, _combinatorId);

        emit NewCombinator(msg.sender, _combinatorId, _multiple);
    }

    function _processStake(uint256 _combinatorId, uint256 _multiple) internal {
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        address tokenAddress;
        uint256 id;
        uint256 tokenAmount;
        uint256 burningRate;
        uint256 feeRate;

        (tokenAddress, tokenAmount, burningRate, feeRate) = manager
            .getTokenAConfig(msg.sender, address(this), _combinatorId);
        IERC20 tokenA = IERC20(tokenAddress);

        require(
            tokenA.transferFrom(
                msg.sender,
                address(this),
                tokenAmount.mul(_multiple)
            ),
            "APWarsCombinatorTokenGameItem:FAIL_TO_STAKE_TOKEN_A"
        );

        (tokenAddress, id, tokenAmount, burningRate, feeRate) = manager
            .getGameItemBConfig(msg.sender, address(this), _combinatorId);
        IERC1155 tokenB = IERC1155(tokenAddress);

        tokenB.safeTransferFrom(
            msg.sender,
            address(this),
            id,
            tokenAmount.mul(_multiple),
            DEFAULT_MESSAGE
        );

        combinators[_combinatorId][msg.sender] = Claimable(
            _combinatorId,
            block.number,
            _multiple
        );
    }

    function _processUnStake(uint256 _combinatorId, uint256 _multiple)
        internal
    {
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        address tokenAddress;
        uint256 id;
        uint256 tokenAmount;
        uint256 burningRate;
        uint256 feeRate;

        (tokenAddress, id, tokenAmount, burningRate, feeRate) = manager
            .getGameItemBConfig(msg.sender, address(this), _combinatorId);
        _transferGameItem(
            msg.sender,
            tokenAddress,
            id,
            tokenAmount,
            _multiple,
            burningRate,
            feeRate
        );
    }

    function _transfer(
        address _player,
        address _tokenAddress,
        uint256 _amount,
        uint256 _multiple,
        uint256 _burningRate,
        uint256 _feeRate,
        bool mint,
        bool mintToDev
    ) internal {
        IERC20 token = IERC20(_tokenAddress);
        uint256 totalAmount = _amount * _multiple;
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;

        if (mint) {
            IAPWarsMintableToken(_tokenAddress).mint(
                address(this),
                totalAmount
            );
        }

        if (_burningRate > 0) {
            burnAmount = totalAmount.mul(_burningRate).div(ONE_HUNDRED_PERCENT);

            IAPWarsBurnManager burnManager = IAPWarsBurnManager(
                burnManagerAddress
            );

            require(
                token.transfer(burnManagerAddress, burnAmount),
                "APWarsCombinatorTokenGameItem:FAIL_TO_BURN_TOKEN"
            );

            burnManager.burn(_tokenAddress);
        }

        if (_feeRate > 0) {
            feeAmount = totalAmount.mul(_feeRate).div(ONE_HUNDRED_PERCENT);

            require(
                token.transfer(feeAddress, feeAmount),
                "APWarsCombinatorTokenGameItem:FAIL_TO_COLLECT_FEE"
            );
        }

        uint256 netAmount = totalAmount.sub(burnAmount).sub(feeAmount);
        if (netAmount > 0) {
            require(
                token.transfer(_player, netAmount),
                "APWarsCombinatorTokenGameItem:FAIL_TO_UNSTAKE_AMOUNT"
            );
        }

        if (mintToDev) {
            uint256 devAmount = totalAmount / DEV_PERCENTAGE;

            if (devAmount > 0) {
                IAPWarsMintableToken(_tokenAddress).mint(feeAddress, devAmount);
            }
        }
    }

    function _transferGameItem(
        address _player,
        address _collectibles,
        uint256 _id,
        uint256 _amount,
        uint256 _multiple,
        uint256 _burningRate,
        uint256 _feeRate
    ) internal {
        IERC1155 token = IERC1155(_collectibles);
        uint256 totalAmount = _amount * _multiple;
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;

        if (_burningRate > 0) {
            burnAmount = totalAmount.mul(_burningRate).div(ONE_HUNDRED_PERCENT);

            IAPWarsBurnManager burnManager = IAPWarsBurnManager(
                burnManagerAddress
            );

            token.safeTransferFrom(
                msg.sender,
                burnManagerAddress,
                _id,
                burnAmount,
                DEFAULT_MESSAGE
            );

            burnManager.burn(_collectibles);
        }

        if (_feeRate > 0) {
            feeAmount = totalAmount.mul(_feeRate).div(ONE_HUNDRED_PERCENT);

            token.safeTransferFrom(
                msg.sender,
                feeAddress,
                _id,
                feeAmount,
                DEFAULT_MESSAGE
            );
        }

        uint256 netAmount = totalAmount.sub(burnAmount).sub(feeAmount);
        if (netAmount > 0) {
            token.safeTransferFrom(
                msg.sender,
                _player,
                _id,
                netAmount,
                DEFAULT_MESSAGE
            );
        }
    }

    function _processTokensTransfers(address _player, uint256 _combinatorId)
        internal
    {
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );
        (uint256 blocks, , ) = manager.getGeneralConfig(
            msg.sender,
            address(this),
            _combinatorId
        );
        Claimable storage claimable = combinators[_combinatorId][_player];

        require(
            claimable.combinatorId > 0,
            "APWarsCombinatorTokenGameItem:INVALID_CONFIG"
        );

        address tokenAddress;
        uint256 tokenAmount;
        uint256 burningRate;
        uint256 feeRate;

        (tokenAddress, tokenAmount, burningRate, feeRate) = manager
            .getTokenAConfig(_player, address(this), _combinatorId);
        _transfer(
            _player,
            tokenAddress,
            tokenAmount,
            claimable.multiple,
            burningRate,
            feeRate,
            false,
            false
        );
    }

    function _clearCombinator(address _player, uint256 _combinatorId) internal {
        combinators[_combinatorId][_player].combinatorId = 0;
        combinatorsCount[_combinatorId] = combinatorsCount[_combinatorId].add(
            1
        );
    }

    function claimGameItemFromTokens(uint256 _combinatorId) public {
        Claimable storage claimable = combinators[_combinatorId][msg.sender];
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        (uint256 blocks, , ) = manager.getGeneralConfig(
            msg.sender,
            address(this),
            _combinatorId
        );

        require(
            block.number.sub(claimable.startBlock) >= blocks,
            "APWarsCombinatorTokenGameItem:INVALID_BLOCK"
        );
        require(
            claimable.combinatorId > 0,
            "APWarsCombinatorTokenGameItem:INVALID_CONFIG"
        );

        _processUnStake(_combinatorId, claimable.multiple);

        (address collectibles, uint256 id, uint256 amount, , ) = manager
            .getGameItemCConfig(msg.sender, address(this), _combinatorId);

        IERC1155 token = IERC1155(collectibles);

        token.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount.mul(claimable.multiple),
            DEFAULT_MESSAGE
        );

        token.safeTransferFrom(
            address(this),
            feeAddress,
            id,
            amount.mul(claimable.multiple) / DEV_PERCENTAGE,
            DEFAULT_MESSAGE
        );

        _clearCombinator(msg.sender, _combinatorId);

        manager.onClaimed(msg.sender, address(this), _combinatorId);

        emit NewGameItemClaim(msg.sender, _combinatorId);
    }

    function claimTokenFromTokens(uint256 _combinatorId) public {
        Claimable storage claimable = combinators[_combinatorId][msg.sender];
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        (uint256 blocks, , ) = manager.getGeneralConfig(
            msg.sender,
            address(this),
            _combinatorId
        );

        require(
            block.number.sub(claimable.startBlock) >= blocks,
            "APWarsCombinatorTokenGameItem:INVALID_BLOCK"
        );
        require(
            claimable.combinatorId > 0,
            "APWarsCombinatorTokenGameItem:INVALID_CONFIG"
        );

        _processUnStake(_combinatorId, claimable.multiple);

        (
            address tokenAddress,
            uint256 tokenAmount,
            uint256 burningRate,
            uint256 feeRate
        ) = manager.getTokenCConfig(msg.sender, address(this), _combinatorId);
        _transfer(
            msg.sender,
            tokenAddress,
            tokenAmount,
            claimable.multiple,
            burningRate,
            feeRate,
            true,
            true
        );

        _clearCombinator(msg.sender, _combinatorId);

        manager.onClaimed(msg.sender, address(this), _combinatorId);

        emit NewTokenClaim(msg.sender, _combinatorId);
    }
}
