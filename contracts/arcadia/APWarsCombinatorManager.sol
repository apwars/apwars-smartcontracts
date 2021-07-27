// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./IAPWarsCombinatorManager.sol";

contract APWarsCombinatorManager is IAPWarsCombinatorManager, AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    using SafeMath for uint256;

    struct Config {
        uint256 blocks;
        uint256 maxMultiple;
        bool isEnabled;
    }

    struct GameItemConfig {
        uint256 combinatorId;
        address collectibles;
        uint256 id;
        uint256 amount;
    }

    struct TokenConfig {
        uint256 combinatorId;
        address tokenAddress;
        uint256 amount;
        uint256 burningRate;
        uint256 feeRate;
    }

    mapping(uint256 => Config) public generalConfig;
    mapping(uint256 => TokenConfig) public tokenAConfig;
    mapping(uint256 => TokenConfig) public tokenBConfig;
    mapping(uint256 => TokenConfig) public tokenCConfig;
    mapping(uint256 => GameItemConfig) public gameItemCConfig;

    event NewTokenConfiguration(
        string token,
        address tokenAddres,
        uint256 amount,
        uint256 burningRate,
        uint256 feeRate
    );

    event NewGameItemConfiguration(
        string gameItem,
        address collectibles,
        uint256 gamteItemId,
        uint256 gameItemAmount
    );

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsCombinatorManager:INVALID_ROLE"
        );
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
        require(_id > 0, "APWarsCombinatorManager:INVALID_ID_ZERO");
        generalConfig[_id] = Config(_blocks, _maxMultiple, isEnabled);
    }

    function setupGameItemC(
        uint256 _combinatorId,
        address _collectibles,
        uint256 _gamteItemId,
        uint256 _gameItemAmount
    ) public onlyRole(CONFIGURATOR_ROLE) {
        gameItemCConfig[_combinatorId] = GameItemConfig(
            _combinatorId,
            _collectibles,
            _gamteItemId,
            _gameItemAmount
        );

        emit NewGameItemConfiguration(
            "C",
            _collectibles,
            _gamteItemId,
            _gameItemAmount
        );
    }

    function setupTokenA(
        uint256 _combinatorId,
        address _tokenAddress,
        uint256 _amount,
        uint256 _burningRate,
        uint256 _feeRate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        tokenAConfig[_combinatorId] = TokenConfig(
            _combinatorId,
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );

        emit NewTokenConfiguration(
            "A",
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );
    }

    function setupTokenB(
        uint256 _combinatorId,
        address _tokenAddress,
        uint256 _amount,
        uint256 _burningRate,
        uint256 _feeRate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        tokenBConfig[_combinatorId] = TokenConfig(
            _combinatorId,
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );

        emit NewTokenConfiguration(
            "B",
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );
    }

    function setupTokenC(
        uint256 _combinatorId,
        address _tokenAddress,
        uint256 _amount,
        uint256 _burningRate,
        uint256 _feeRate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        tokenCConfig[_combinatorId] = TokenConfig(
            _combinatorId,
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );

        emit NewTokenConfiguration(
            "C",
            _tokenAddress,
            _amount,
            _burningRate,
            _feeRate
        );
    }

    function getGeneralConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        public
        view
        override
        returns (
            uint256 blocks,
            uint256 maxMultiple,
            bool isEnabled
        )
    {
        blocks = generalConfig[_combinatorId].blocks;
        maxMultiple = generalConfig[_combinatorId].maxMultiple;
        isEnabled = generalConfig[_combinatorId].isEnabled;
    }

    function getTokenAConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        public
        view
        override
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        )
    {
        require(
            tokenAConfig[_combinatorId].combinatorId == _combinatorId,
            "APWarsCombinatorManager:INVALID_ID_A"
        );

        tokenAddress = tokenAConfig[_combinatorId].tokenAddress;
        amount = tokenAConfig[_combinatorId].amount;
        burningRate = tokenAConfig[_combinatorId].burningRate;
        feeRate = tokenAConfig[_combinatorId].feeRate;
    }

    function getTokenBConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        public
        view
        override
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        )
    {
        require(
            tokenBConfig[_combinatorId].combinatorId == _combinatorId,
            "APWarsCombinatorManager:INVALID_ID_B"
        );

        tokenAddress = tokenBConfig[_combinatorId].tokenAddress;
        amount = tokenBConfig[_combinatorId].amount;
        burningRate = tokenBConfig[_combinatorId].burningRate;
        feeRate = tokenBConfig[_combinatorId].feeRate;
    }

    function getTokenCConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        public
        view
        override
        returns (
            address tokenAddress,
            uint256 amount,
            uint256 burningRate,
            uint256 feeRate
        )
    {
        require(
            tokenCConfig[_combinatorId].combinatorId == _combinatorId,
            "APWarsCombinatorManager:INVALID_ID_C"
        );

        tokenAddress = tokenCConfig[_combinatorId].tokenAddress;
        amount = tokenCConfig[_combinatorId].amount;
        burningRate = tokenCConfig[_combinatorId].burningRate;
        feeRate = tokenCConfig[_combinatorId].feeRate;
    }

    function getGameItemCConfig(
        address _player,
        address _source,
        uint256 _combinatorId
    )
        public
        view
        override
        returns (
            address collectibles,
            uint256 id,
            uint256 amount
        )
    {
        require(
            gameItemCConfig[_combinatorId].combinatorId == _combinatorId,
            "APWarsCombinatorManager:INVALID_ID_GC"
        );

        collectibles = gameItemCConfig[_combinatorId].collectibles;
        id = gameItemCConfig[_combinatorId].id;
        amount = gameItemCConfig[_combinatorId].amount;
    }

    function onClaimed(
        address _player,
        address _source,
        uint256 _combinatorId
    )         
        public
        view
        override
        {

        }
}
