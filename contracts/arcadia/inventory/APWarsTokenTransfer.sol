// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract APWarsTokenTransfer is AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    event NewTransfer(
        IERC20 token,
        address sender,
        address spender,
        address recipient,
        uint256 amount
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TRANSFER_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "APWarsTokenTransfer:INVALID_ROLE"
        );
        _;
    }

    function transferFrom(
        IERC20 _token,
        address _spender,
        address _recipient,
        uint256 _amount
    ) public onlyRole(TRANSFER_ROLE) {
        require(
            _spender == tx.origin,
            "APWarsTokenTransfer:_from != tx.origin"
        );
        require(
            _token.transferFrom(_spender, _recipient, _amount),
            "APWarsTokenTransfer:failed"
        );

        emit NewTransfer(_token, msg.sender, _spender, _recipient, _amount);
    }
}
