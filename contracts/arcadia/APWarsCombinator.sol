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

contract APWarsCombinator is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes private DEFAULT_MESSAGE;

    struct Claimable {
        uint256 combinatorId;
        uint256 startBlock;
        uint256 multiple;
        bool isClaimed;
    }

    mapping(uint256 => mapping(address => Claimable)) public combinators;
    mapping(uint256 => uint256) public combinatorsCount;
    address public feeAddress;
    address public burnManagerAddress;
    address public combinatorManagerAddress;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsCombinator:INVALID_ROLE");
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
    }

    function combineTokens(uint256 _combinatorId, uint256 _multiple) public {
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );
        (uint256 blocks, uint256 maxMultiple, bool isEnabled) = manager
        .getGeneralConfig(msg.sender, address(this), _combinatorId);

        require(isEnabled, "APWarsCombinator:DISABLED_COMBINATOR");

        require(
            combinators[_combinatorId][msg.sender].combinatorId == 0,
            "APWarsCombinator:COMBINATOR_IS_EXCLUSIVE"
        );

        require(
            _multiple > 0 && _multiple <= maxMultiple,
            "APWarsCombinator:INVALID_MULTIPLE"
        );

        address tokenAddress;
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
            "APWarsCombinator:FAIL_TO_STAKE_TOKEN_A"
        );

        (tokenAddress, tokenAmount, burningRate, feeRate) = manager
        .getTokenBConfig(msg.sender, address(this), _combinatorId);
        IERC20 tokenB = IERC20(tokenAddress);

        require(
            tokenB.transferFrom(
                msg.sender,
                address(this),
                tokenAmount.mul(_multiple)
            ),
            "APWarsCombinator:FAIL_TO_STAKE_TOKEN_B"
        );

        combinators[_combinatorId][msg.sender] = Claimable(
            _combinatorId,
            block.number,
            _multiple,
            false
        );
    }

    function _transfer(
        address _player,
        address _tokenAddress,
        uint256 _amount,
        uint256 _multiple,
        uint256 _burningRate,
        uint256 _feeRate,
        bool mint
    ) internal {
        IERC20 token = IERC20(_tokenAddress);
        uint256 totalAmount = _amount * _multiple;
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;

        if (mint) {
            IAPWarsMintableToken mintableToken = IAPWarsMintableToken(
                _tokenAddress
            );
            mintableToken.mint(totalAmount);
        }

        if (_burningRate > 0) {
            burnAmount = totalAmount.mul(_burningRate).div(ONE_HUNDRED_PERCENT);

            IAPWarsBurnManager burnManager = IAPWarsBurnManager(
                burnManagerAddress
            );

            require(
                token.transfer(burnManagerAddress, burnAmount),
                "APWarsCombinator:FAIL_TO_BURN_TOKEN"
            );

            burnManager.burn(_tokenAddress);
        }

        if (_feeRate > 0) {
            feeAmount = totalAmount.mul(_feeRate).div(ONE_HUNDRED_PERCENT);

            require(
                token.transfer(feeAddress, feeAmount),
                "APWarsCombinator:FAIL_TO_COLLECT_FEE"
            );
        }

        uint256 netAmount = totalAmount.sub(burnAmount).sub(feeAmount);

        require(
            token.transfer(_player, netAmount),
            "APWarsCombinator:FAIL_TO_UNSTAKE_AMOUNT"
        );
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

        require(claimable.combinatorId > 0, "APWarsCombinator:INVALID_CONFIG");
        require(!claimable.isClaimed, "APWarsCombinator:ALREADY_CLAIMED");
        require(
            block.number.sub(claimable.startBlock) >= blocks,
            "APWarsCombinator:INVALID_BLOCK"
        );

        (
            address tokenAddress,
            uint256 tokenAmount,
            uint256 burningRate,
            uint256 feeRate
        ) = manager.getTokenAConfig(_player, address(this), _combinatorId);
        _transfer(
            _player,
            tokenAddress,
            tokenAmount,
            claimable.multiple,
            burningRate,
            feeRate,
            false
        );

        (tokenAddress, tokenAmount, burningRate, feeRate) = manager
        .getTokenBConfig(_player, address(this), _combinatorId);
        _transfer(
            _player,
            tokenAddress,
            tokenAmount,
            claimable.multiple,
            burningRate,
            feeRate,
            false
        );
    }

    function claimGameItemFromTokens(uint256 _combinatorId) public {
        Claimable storage claimable = combinators[_combinatorId][msg.sender];
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        _processTokensTransfers(msg.sender, _combinatorId);

        (address collectibles, uint256 id, uint256 amount) = manager
        .getGameItemCConfig(msg.sender, address(this), _combinatorId);

        IERC1155 token = IERC1155(collectibles);

        token.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount.mul(claimable.multiple),
            DEFAULT_MESSAGE
        );

        claimable.isClaimed = true;
    }

    function claimTokenFromTokens(uint256 _combinatorId) public {
        Claimable storage claimable = combinators[_combinatorId][msg.sender];
        IAPWarsCombinatorManager manager = IAPWarsCombinatorManager(
            combinatorManagerAddress
        );

        _processTokensTransfers(msg.sender, _combinatorId);

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
            true
        );

        claimable.isClaimed = true;
    }
}
