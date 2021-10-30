// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../APWarsFarmManagerV2.sol";
import "../APWarsFarmManagerV3.sol";
import "../libs/IBEP20.sol";
import "../IAPWarsBaseToken.sol";

contract APWarsFarmManagerOwner is AccessControl {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE_MASS = keccak256("CONFIGURATOR_ROLE_MASS");

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsFarmManagerOwner: INVALID_ROLE"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
        _setupRole(CONFIGURATOR_ROLE_MASS, _msgSender());
    }

    function transferOwnership(Ownable _ownable, address _owner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ownable.transferOwnership(_owner);
    }

    function addV3(
        APWarsFarmManagerV3 _farming,
        uint256 _allocPoint,
        IBEP20 _lpToken,
        IAPWarsBurnManager _burnManager,
        bool _withUpdate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        _farming.add(_allocPoint, _lpToken, _burnManager, _withUpdate);
    }

    function setV3(
        APWarsFarmManagerV3 _farming,
        uint256 _pid,
        uint256 _allocPoint,
        IAPWarsBurnManager _burnManager,
        bool _withUpdate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        _farming.set(_pid, _allocPoint, _burnManager, _withUpdate);
    }

    function addV2(
        APWarsFarmManagerV2 _farming,
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        _farming.add(_allocPoint, _lpToken, _depositFeeBP, _withUpdate);
    }

    function setV2(
        APWarsFarmManagerV2 _farming,
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyRole(CONFIGURATOR_ROLE) {
        _farming.set(_pid, _allocPoint, _depositFeeBP, _withUpdate);
    }

    function updateEmissionRate(
        APWarsFarmManagerV2 _farming,
        uint256 _tokenPerBlock
    ) public onlyRole(CONFIGURATOR_ROLE) {
        _farming.updateEmissionRate(_tokenPerBlock);
    }

    function massUpdateEmissionRate(
        APWarsFarmManagerV2[] memory _farming,
        uint256[] memory _tokenPerBlock
    ) public onlyRole(CONFIGURATOR_ROLE_MASS) {
        require(
            _farming.length == _tokenPerBlock.length,
            "APWarsFarmManagerOwner: INVALID_LENGTH"
        );
        for (uint256 i = 0; i < _farming.length; i++) {
            updateEmissionRate(_farming[i], _tokenPerBlock[i]);
        }
    }

    function massUpdateAllocPointV2(
        APWarsFarmManagerV2[] memory _farming,
        uint256[] memory _pid,
        uint256[] memory _allocPoint
    ) public onlyRole(CONFIGURATOR_ROLE_MASS) {
        require(
            _farming.length == _pid.length && _pid.length == _allocPoint.length,
            "APWarsFarmManagerOwner: INVALID_LENGTH"
        );

        for (uint256 i = 0; i < _farming.length; i++) {
            (, , , , uint16 depositFeeBP) = _farming[i].poolInfo(
                _pid[i]
            );
            setV2(_farming[i], _pid[i], _allocPoint[i], depositFeeBP, true);
        }
    }

    function massUpdateAllocPointV3(
        APWarsFarmManagerV3[] memory _farming,
        uint256[] memory _pid,
        uint256[] memory _allocPoint
    ) public onlyRole(CONFIGURATOR_ROLE_MASS) {
        require(
            _farming.length == _pid.length && _pid.length == _allocPoint.length,
            "APWarsFarmManagerOwner: INVALID_LENGTH"
        );

        for (uint256 i = 0; i < _farming.length; i++) {
            (, , , , IAPWarsBurnManager burnManager) = _farming[i].poolInfo(
                _pid[i]
            );
            setV3(_farming[i], _pid[i], _allocPoint[i], burnManager, true);
        }
    }

    function massUpdateBurnManagerV3(
        APWarsFarmManagerV3[] memory _farming,
        uint256[] memory _pid,
        IAPWarsBurnManager[] memory _burnManager
    ) public onlyRole(CONFIGURATOR_ROLE_MASS) {
        require(
            _farming.length == _pid.length && _pid.length == _burnManager.length,
            "APWarsFarmManagerOwner: INVALID_LENGTH"
        );

        for (uint256 i = 0; i < _farming.length; i++) {
            (, uint256 allocPoint, , , ) = _farming[i].poolInfo(
                _pid[i]
            );
            setV3(_farming[i], _pid[i], allocPoint, _burnManager[i], true);
        }
    }

    function massUpdateDepositFeeV2(
        APWarsFarmManagerV2[] memory _farming,
        uint256[] memory _pid,
        uint16[] memory _depositFee
    ) public onlyRole(CONFIGURATOR_ROLE_MASS) {
        require(
            _farming.length == _pid.length && _pid.length == _depositFee.length,
            "APWarsFarmManagerOwner: INVALID_LENGTH"
        );

        for (uint256 i = 0; i < _farming.length; i++) {
            (, uint256 allocPoint, , , ) = _farming[i].poolInfo(
                _pid[i]
            );
            setV2(_farming[i], _pid[i], allocPoint, _depositFee[i], true);
        }
    }
}
