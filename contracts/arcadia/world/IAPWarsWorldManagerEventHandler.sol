pragma solidity >=0.6.0;

import "../nft/APWarsBaseNFT.sol";
import "../nft/APWarsBaseNFTStorage.sol";
import "../inventory/APWarsTokenTransfer.sol";
import "../inventory/APWarsCollectiblesTransfer.sol";

interface IAPWarsWorldManagerEventHandler {
    function onBuyLand(
        address _sender,
        address _player,
        uint256 _worldId,
        uint256 _x,
        uint256 _price
    ) external;

    function onBuildFoundation(
        address _sender,
        address _player,
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) external;

    function onDestroyFoundation(
        address _sender,
        address _player,
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _foundationType
    ) external;
}
