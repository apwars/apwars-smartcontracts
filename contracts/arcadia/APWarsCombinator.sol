// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../utils/IAPWarsBurnManager.sol";

contract APWarsCombinator is AccessControl, ERC1155Holder {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes private DEFAULT_MESSAGE;

    struct Config {
        uint256 blocks;
        uint256 maxMultiple;
        bool isEnabled;
    }

    struct GameItemConfig {
        address collectibles;
        uint256 id;
        uint256 amount;
    }

    struct TokenConfig {
        address tokenAddress;
        uint256 amount;
        uint256 burningRate;
        uint256 feeRate;
    }

    struct Claimable {
        uint256 combinatorId;
        uint256 allowedBlock;
        uint256 multiple;
        bool isClaimed;
    }

    mapping(uint256 => Config) public generalConfig;
    mapping(uint256 => TokenConfig) public tokenAConfig;
    mapping(uint256 => TokenConfig) public tokenBConfig;
    mapping(uint256 => GameItemConfig) public gameItemConfig;

    mapping(uint256 => mapping(address => Claimable)) combinators;
    address feeAddress;
    address burnManagerAddress;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsCombinator:INVALID_ROLE");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    function setupCombinator(
        uint256 _id,
        uint256 _blocks,
        uint256 _maxMultiple,
        bool isEnabled
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(_id > 0, "APWarsCombinator:INVALID_ID");
        generalConfig[_id] = Config(_blocks, _maxMultiple, isEnabled);
    }

    function setupGameItem(
        uint256 _combinatorId,
        address _collectibles,
        uint256 _gamteItemId,
        uint256 _gameItemAmount
    ) public onlyRole(CONFIGURATOR_ROLE) {
        gameItemConfig[_combinatorId] = GameItemConfig(
            _collectibles,
            _gamteItemId,
            _gameItemAmount
        );
    }

    function setupTokens(
        uint256 _combinatorId,
        address _tokenA,
        uint256 _tokenAAmount,
        uint256 _tokenABurningRate,
        uint256 _tokenAFeeRate,
        address _tokenB,
        uint256 _tokenBAmount,
        uint256 _tokenBBurningRate,
        uint256 _tokenBFeeRate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        tokenAConfig[_combinatorId] = TokenConfig(
            _tokenA,
            _tokenAAmount,
            _tokenABurningRate,
            _tokenAFeeRate
        );
        tokenBConfig[_combinatorId] = TokenConfig(
            _tokenB,
            _tokenBAmount,
            _tokenBBurningRate,
            _tokenBFeeRate
        );
    }

    function combine(uint256 _combinatorId, uint256 _multiple) public {
        Config storage config = generalConfig[_combinatorId];

        require(
            combinators[_combinatorId][msg.sender].combinatorId == 0,
            "APWarsCombinator:COMBINATOR_IS_EXCLUSIVE"
        );

        require(
            _multiple > 0 && _multiple <= config.maxMultiple,
            "APWarsCombinator:INVALID_MULTIPLE"
        );

        IERC20 tokenA = IERC20(tokenAConfig[_combinatorId].tokenAddress);
        IERC20 tokenB = IERC20(tokenBConfig[_combinatorId].tokenAddress);

        require(
            tokenA.transferFrom(
                msg.sender,
                address(this),
                tokenAConfig[_combinatorId].amount.mul(_multiple)
            ),
            "APWarsCombinator:FAIL_TO_STAKE_TOKEN_A"
        );

        require(
            tokenB.transferFrom(
                msg.sender,
                address(this),
                tokenBConfig[_combinatorId].amount.mul(_multiple)
            ),
            "APWarsCombinator:FAIL_TO_STAKE_TOKEN_A"
        );

        combinators[_combinatorId][msg.sender] = Claimable(
            _combinatorId,
            block.number + config.blocks,
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
        uint256 _feeRate
    ) internal {
        IERC20 token = IERC20(_tokenAddress);
        uint256 totalAmount = _amount * _multiple;
        uint256 burnAmount = 0;
        uint256 feeAmount = 0;

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

        uint256 netAmout = totalAmount.sub(burnAmount).sub(feeAmount);

        require(
            token.transfer(_player, netAmout),
            "APWarsCombinator:FAIL_TO_UNSTAKE_AMOUNT"
        );
    }

    function claim(address _player, uint256 _combinatorId) public {
        Config storage config = generalConfig[_combinatorId];
        Claimable storage claimable = combinators[_combinatorId][_player];

        require(claimable.combinatorId > 0, "APWarsCombinator:INVALID_CONFIG");
        require(!claimable.isClaimed, "APWarsCombinator:IS_CLAIMED");
        require(
            claimable.allowedBlock < block.number,
            "APWarsCombinator:INVALID_BLOCK"
        );

        _transfer(
            _player,
            tokenAConfig[_combinatorId].tokenAddress,
            tokenAConfig[_combinatorId].amount,
            claimable.multiple,
            tokenAConfig[_combinatorId].burningRate,
            tokenAConfig[_combinatorId].feeRate
        );
        _transfer(
            _player,
            tokenBConfig[_combinatorId].tokenAddress,
            tokenBConfig[_combinatorId].amount,
            claimable.multiple,
            tokenBConfig[_combinatorId].burningRate,
            tokenBConfig[_combinatorId].feeRate
        );

        IERC1155 token = IERC1155(gameItemConfig[_combinatorId].collectibles);

        token.safeTransferFrom(
            address(this),
            _player,
            gameItemConfig[_combinatorId].id,
            gameItemConfig[_combinatorId].amount.mul(claimable.multiple),
            DEFAULT_MESSAGE
        );
    }
}
