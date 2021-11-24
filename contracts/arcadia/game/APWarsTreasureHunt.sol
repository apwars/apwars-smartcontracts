// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./APWarsTreasureHuntSetup.sol";
import "./APWarsTreasureHuntEventHandler.sol";

contract APWarsTreasureHunt is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    struct Land {
        uint256 worldId;
        uint256 x;
        uint256 y;
    }

    struct TreasureHuntSettings {
        uint256 worldId;
        uint256 deadline;
        APWarsTreasureHuntSetup setup;
        address winner;
        uint256 selectedX;
        uint256 selectedY;
        uint256 selectedInnerX;
        uint256 selectedInnerY;
        bool isClosed;
        uint256 walletLimit;
    }

    struct UserTreasureHunt {
        uint256 x;
        uint256 y;
        uint256 innerX;
        uint256 innerY;
        bool isValid;
    }

    mapping(uint256 => Land[]) private allowedLands;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) isLandAllowed;
    TreasureHuntSettings[] huntSettings;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => address))))) hunters;
    bytes32 randomSource;
    mapping(uint256 => mapping(address => UserTreasureHunt[])) userTreasureHunt;
    APWarsTreasureHuntEventHandler eventHandler;

    event HuntClosed(
        address sender,
        uint256 huntId,
        uint256 worldId,
        uint256 selectedX,
        uint256 selectedY,
        uint256 selectedInnerX,
        uint256 selectedInnerY,
        address winner
    );

    event NewHunter(
        address sender,
        uint256 huntId,
        uint256 worldId,
        uint256 selectedX,
        uint256 selectedY,
        uint256 selectedInnerX,
        uint256 selectedInnerY
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "APWarsTreasureHunt:INVALID_ROLE");
        _;
    }

    function setup(APWarsTreasureHuntEventHandler _eventHandler)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        eventHandler = _eventHandler;
    }

    function setIsLandAllowed(
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        bool _isLandAllowed
    ) public onlyRole(CONFIGURATOR_ROLE) {
        if (_isLandAllowed && !getIsLandAllowed(_worldId, _x, _y)) {
            allowedLands[_worldId].push(Land(_worldId, _x, _y));
        }

        isLandAllowed[_worldId][_x][_y] = _isLandAllowed;
    }

    function getIsLandAllowed(
        uint256 _worldId,
        uint256 _x,
        uint256 _y
    ) public returns (bool) {
        return isLandAllowed[_worldId][_x][_y];
    }

    function getHunters(
        uint256 _huntId,
        uint256 _x,
        uint256 _y
    ) public view returns (address[] memory addresses) {
        addresses = new address[](100);

        uint256 index = 0;
        for (uint256 i = 0; i < 10; i++) {
            for (uint256 j = 0; j < 10; j++) {
                addresses[index] = hunters[huntSettings[_huntId].worldId][_x][
                    _y
                ][i][j];

                index++;
            }
        }
    }

    function addTreasureHunt(
        uint256 _worldId,
        uint256 _deadline,
        APWarsTreasureHuntSetup _setup,
        uint256 _walletLimit
    ) public onlyRole(CONFIGURATOR_ROLE) {
        huntSettings.push(
            TreasureHuntSettings(
                _worldId,
                _deadline,
                _setup,
                address(0),
                0,
                0,
                0,
                0,
                false,
                _walletLimit
            )
        );
    }

    function updateTreasureHunt(
        uint256 _huntId,
        uint256 _worldId,
        uint256 _deadline,
        APWarsTreasureHuntSetup _setup,
        uint256 _walletLimit
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            !huntSettings[_huntId].isClosed,
            "APWarsTreasureHunt:ALREADY_CLOSED"
        );

        huntSettings[_huntId].worldId = _worldId;
        huntSettings[_huntId].deadline = _deadline;
        huntSettings[_huntId].setup = _setup;
        huntSettings[_huntId].walletLimit = _walletLimit;
    }

    function setAllowedLands(
        uint256 _worldId,
        uint256[] calldata _x,
        uint256[] calldata _y
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _x.length == _x.length,
            "APWarsWorldManager:INVALID_ARRAY_LENTH"
        );

        for (uint256 i = 0; i < _x.length; i++) {
            setIsLandAllowed(_worldId, _x[i], _y[i], true);
        }
    }

    function resetAllowedLands(uint256 _worldId)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        for (uint256 i = 0; i < allowedLands[_worldId].length; i++) {
            setIsLandAllowed(
                _worldId,
                allowedLands[_worldId][i].x,
                allowedLands[_worldId][i].y,
                false
            );
        }
    }

    function random(uint256 _salt, uint256 _maxNumber)
        public
        view
        returns (uint256)
    {
        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        bytes32 _structHash = keccak256(
            abi.encode(_salt, _blockhash, gasLeft, randomSource)
        );
        uint256 randomNumber = uint256(_structHash);

        assembly {
            randomNumber := add(mod(randomNumber, _maxNumber), 1)
        }

        return randomNumber;
    }

    function join(
        uint256 _huntId,
        uint256 _x,
        uint256 _y,
        uint256 _innerX,
        uint256 _innerY
    ) public {
        require(
            isLandAllowed[huntSettings[_huntId].worldId][_x][_y],
            "APWarsTreasureHunt:INVALID_LAND"
        );
        require(
            hunters[huntSettings[_huntId].worldId][_x][_y][_innerX][_innerY] ==
                address(0),
            "APWarsTreasureHunt:ALREADY_HUNTING"
        );
        require(
            !huntSettings[_huntId].isClosed,
            "APWarsTreasureHunt:ALREADY_CLOSED"
        );
        require(
            huntSettings[_huntId].walletLimit >
                userTreasureHunt[_huntId][msg.sender].length,
            "APWarsTreasureHunt:WALLET_AMOUNT_EXCEEDED"
        );

        huntSettings[_huntId].setup.chargeFee(
            msg.sender,
            huntSettings[_huntId].worldId,
            _x,
            _y
        );
        hunters[huntSettings[_huntId].worldId][_x][_y][_innerX][_innerY] = msg
            .sender;
        userTreasureHunt[_huntId][msg.sender].push(
            UserTreasureHunt(_x, _y, _innerX, _innerY, true)
        );

        randomSource = keccak256(
            abi.encode(blockhash(block.number - 1), gasleft(), randomSource)
        );

        eventHandler.onJoin(
            address(this),
            msg.sender,
            _huntId,
            huntSettings[_huntId].worldId,
            _x,
            _y,
            _innerX,
            _innerY
        );

        emit NewHunter(
            msg.sender,
            _huntId,
            huntSettings[_huntId].worldId,
            _x,
            _y,
            _innerX,
            _innerY
        );
    }

    function getHuntsLength() public view returns (uint256) {
        return huntSettings.length;
    }

    function getHuntByIndex(uint256 _huntId)
        public
        view
        returns (
            uint256 worldId,
            uint256 deadline,
            APWarsTreasureHuntSetup setup,
            address winner,
            uint256 selectedX,
            uint256 selectedY,
            uint256 selectedInnerX,
            uint256 selectedInnerY,
            bool isClosed,
            uint256 walletLimit
        )
    {
        worldId = huntSettings[_huntId].worldId;
        deadline = huntSettings[_huntId].deadline;
        setup = huntSettings[_huntId].setup;
        winner = huntSettings[_huntId].winner;
        selectedX = huntSettings[_huntId].selectedX;
        selectedY = huntSettings[_huntId].selectedY;
        selectedInnerX = huntSettings[_huntId].selectedInnerX;
        selectedInnerY = huntSettings[_huntId].selectedInnerY;
        isClosed = huntSettings[_huntId].isClosed;
        walletLimit = huntSettings[_huntId].walletLimit;
    }

    function getHuntsLengthByPlayer(uint256 _huntId, address _player)
        public
        view
        returns (uint256)
    {
        return userTreasureHunt[_huntId][_player].length;
    }

    function getPlayerHuntByIndex(
        uint256 _huntId,
        address _player,
        uint256 _id
    )
        public
        view
        returns (
            uint256 x,
            uint256 y,
            uint256 innerX,
            uint256 innerY,
            bool isValid
        )
    {
        x = userTreasureHunt[_huntId][_player][_id].x;
        y = userTreasureHunt[_huntId][_player][_id].y;
        innerX = userTreasureHunt[_huntId][_player][_id].innerX;
        innerY = userTreasureHunt[_huntId][_player][_id].innerY;
        isValid = userTreasureHunt[_huntId][_player][_id].isValid;
    }

    function distributeReward(uint256 _huntId) public {
        require(
            _huntId < huntSettings.length,
            "APWarsTreasureHunt:INVALID_HUNTER_ID"
        );

        require(
            huntSettings[_huntId].deadline < block.number,
            "APWarsTreasureHunt:INVALID_BOCK_NUMBER"
        );

        require(
            !huntSettings[_huntId].isClosed,
            "APWarsTreasureHunt:ALREADY_CLOSED"
        );

        uint256 randomAllowedLand = random(
            0,
            allowedLands[huntSettings[_huntId].worldId].length
        );

        if (randomAllowedLand > 0) {
            randomAllowedLand = randomAllowedLand.sub(1);
        }

        uint256 randomXSpot = random(randomAllowedLand, 10);
        uint256 randomYSpot = random(randomXSpot, 10);

        if (randomXSpot > 0) {
            randomXSpot = randomXSpot.sub(1);
        }
        if (randomYSpot > 0) {
            randomYSpot = randomYSpot.sub(1);
        }

        huntSettings[_huntId].selectedX = allowedLands[
            huntSettings[_huntId].worldId
        ][randomAllowedLand].x;
        huntSettings[_huntId].selectedY = allowedLands[
            huntSettings[_huntId].worldId
        ][randomAllowedLand].y;
        huntSettings[_huntId].selectedInnerX = randomXSpot;
        huntSettings[_huntId].selectedInnerY = randomYSpot;

        address winner = hunters[huntSettings[_huntId].worldId][
            huntSettings[_huntId].selectedX
        ][huntSettings[_huntId].selectedY][
            huntSettings[_huntId].selectedInnerX
        ][huntSettings[_huntId].selectedInnerY];

        huntSettings[_huntId].winner = winner;
        huntSettings[_huntId].isClosed = true;

        huntSettings[_huntId].setup.closeReward(_huntId, winner);

        eventHandler.onDistributeReward(
            address(this),
            msg.sender,
            _huntId,
            winner
        );

        emit HuntClosed(
            msg.sender,
            _huntId,
            huntSettings[_huntId].worldId,
            huntSettings[_huntId].selectedX,
            huntSettings[_huntId].selectedY,
            huntSettings[_huntId].selectedInnerX,
            huntSettings[_huntId].selectedInnerY,
            winner
        );
    }
}
