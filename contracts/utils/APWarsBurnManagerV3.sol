// // SPDX-License-Identifier: GPL-v3
// pragma solidity >=0.6.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "../libs/IBEP20.sol";
// import "../IAPWarsBaseToken.sol";
// import "./IAPWarsBurnManager.sol";
// import "../arcadia/inventory/APWarsCollectiblesTransfer.sol";

// contract APWarsBurnManagerV2 is Ownable, IAPWarsBurnManager {
//     uint16 private constant ONE_HUNDRED_PERCENT = 10000;
//     uint16 private constant ONE_PERCENT = 100;
//     ERC1155 private collectibles;
//     mapping(address => uint256) private burnedAmount;
//     address previousBurnManager;
//     address devAddress;
//     mapping(IBEP20 => bool) burnableToken;
//     bytes private DEFAULT_MESSAGE;

//     // mapping(uint256 => uint16) goldSaverConfig;
//     // uint256[] goldSavers;

//     // mapping(address => mapping(uint256 => uint16)) burnSaverAmount;
//     // mapping(address => uint256[]) burnSavers;

//     struct BurnSaver {
//         uint256 id10;
//         uint256 id15;
//         uint256 id20;
//         uint256 id10Spendable;
//         uint256 id15Spendable;
//         uint256 id20Spendable;
//     }

//     mapping(address => BurnSaver[]) burnSavers;
//     APWarsCollectiblesTransfer private collectiblesTransfer;

//     event Burned(
//         address farmManager,
//         address token,
//         address player,
//         uint256 pid,
//         uint256 userAmount,
//         uint256 burnAmount
//     );

//     event BurnSaverAmountChanged(address token, uint256 id, uint256 amount);

//     event BurnedAll(address token, uint256 burnAmount);

//     constructor(address _devAddress) {
//         devAddress = _devAddress;
//     }

//     function setPreviousBurnManager(address _previousBurnManager)
//         public
//         onlyOwner
//     {
//         previousBurnManager = _previousBurnManager;
//     }

//     function getPreviousBurnManager() public view returns (address) {
//         return previousBurnManager;
//     }

//     function setBurnableToken(IBEP20 _token, bool isBurnable) public onlyOwner {
//         burnableToken[_token] = isBurnable;
//     }

//     function isBurnableToken(IBEP20 _token) public view returns (bool) {
//         return burnableToken[_token];
//     }

//     function getPreviousBurnManagerAddress() public view returns (address) {
//         return previousBurnManager;
//     }

//     function getDevAddress() public view returns (address) {
//         return devAddress;
//     }

//     // function checkIfBurnSaverIsConfigured(address _token, uint256 _id)
//     //     public
//     //     view
//     //     returns (bool)
//     // {
//     //     uint256[] storage savers = burnSavers[_token];

//     //     for (uint256 i = 0; i < savers.length; i++) {
//     //         if (savers[i] == _id) {
//     //             return true;
//     //         }
//     //     }

//     //     return false;
//     // }

//     // function setBurnSaverAmount(
//     //     address _token,
//     //     uint256 _id,
//     //     uint16 _amount
//     // ) public onlyOwner {
//     //     if (!checkIfBurnSaverIsConfigured(_token, _id)) {
//     //         burnSavers[_token].push(_id);
//     //     }

//     //     burnSaverAmount[_token][_id] = _amount;

//     //     emit BurnSaverAmountChanged(_token, _id, _amount);
//     // }

//     function addBurnSaver(
//         address _token,
//         uint256 _id10,
//         uint256 _id15,
//         uint256 _id20,
//         uint256 _id10Spendable,
//         uint256 _id15Spendable,
//         uint256 _id20Spendable
//     ) public onlyOwner {
//         burnSavers[_token].push(
//             BurnSaver(
//                 _id10,
//                 _id15,
//                 _id20,
//                 _id10Spendable,
//                 _id15Spendable,
//                 _id20Spendable
//             )
//         );
//     }

//     // function getBurnSaverAmountByIndex(address _token, uint256 _index)
//     //     public
//     //     view
//     //     returns (uint16)
//     // {
//     //     return burnSaverAmount[_token][burnSavers[_token][_index]];
//     // }

//     // function getBurnSaverAmount(address _token, uint256 _id)
//     //     public
//     //     view
//     //     returns (uint16)
//     // {
//     //     return burnSaverAmount[_token][_id];
//     // }

//     // function getPlayerBalanceOfByIndex(
//     //     address _token,
//     //     address _player,
//     //     uint256 _index
//     // ) public view returns (uint256) {
//     //     return collectibles.balanceOf(_player, burnSavers[_token][_index]);
//     // }

//     function getPlayerBalanceOfById(address _player, uint256 _id)
//         public
//         view
//         returns (uint256)
//     {
//         return collectibles.balanceOf(_player, _id);
//     }

//     function getCompundBurnSaverByPlayer(address _token, address _player)
//         public
//         view
//         returns (uint16)
//     {
//         (
//             uint16 compoundBurnSaver,
//         ) = getCompundBurnSaverAndSpandablesIdsByPlayer(_token, _player);

//         return compoundBurnSaver;
//     }

//     function getCompundBurnSaverAndSpandablesIdsByPlayer(
//         address _token,
//         address _player
//     )
//         public
//         view
//         returns (
//             uint16 compoundBurnSaver,
//             uint256[] memory idSpandable
//         )
//     {
//         uint16 burnSaver = 0;
//         uint16 burnSaver10 = 0;
//         uint16 burnSaver15 = 0;
//         uint16 burnSaver20 = 0;
//         // bool isPerpetual15 = false;
//         // bool isPerpetual20 = false;
//         uint256[] memory idSpandable;
//         // uint256 idSpandable15 = 0;
//         // uint256 idSpandable20 = 0;

//         for (uint256 i = 0; i < burnSavers[_token].length; i++) {
//             if (
//                 burnSaver10 == 0 &&
//                 collectibles.balanceOf(_player, burnSavers[_token][i].id10) > 0
//             ) {
//                 burnSaver10 = 1000;
//                 burnSaver = burnSaver + burnSaver10;
//                 isPerpetual[10] = true;
//             } else if (
//                 burnSaver10 == 0 &&
//                 collectibles.balanceOf(
//                     _player,
//                     burnSavers[_token][i].id10Spendable
//                 ) >
//                 0
//             ) {
//                 idSpandable[10] = burnSavers[_token][i].id10Spendable;
//                 burnSaver10 = 1000;
//                 burnSaver = burnSaver + burnSaver10;
//             }

//             if (
//                 burnSaver15 == 0 &&
//                 collectibles.balanceOf(_player, burnSavers[_token][i].id15) > 0
//             ) {
//                 burnSaver15 = 1500;
//                 burnSaver = burnSaver + burnSaver15;
//                 isPerpetual[15] = true;
//             } else if (
//                 burnSaver15 == 0 &&
//                 collectibles.balanceOf(
//                     _player,
//                     burnSavers[_token][i].id15Spendable
//                 ) >
//                 0
//             ) {
//                 idSpandable[15] = burnSavers[_token][i].id15Spendable;
//                 burnSaver15 = 1500;
//                 burnSaver = burnSaver + burnSaver15;
//             }

//             if (
//                 burnSaver20 == 0 &&
//                 collectibles.balanceOf(_player, burnSavers[_token][i].id20) > 0
//             ) {
//                 burnSaver20 = 2000;
//                 burnSaver = burnSaver + burnSaver20;
//                 isPerpetual[20] = true;
//             } else if (
//                 burnSaver20 == 0 &&
//                 collectibles.balanceOf(
//                     _player,
//                     burnSavers[_token][i].id20Spendable
//                 ) >
//                 0
//             ) {
//                 idSpandable[20] = burnSavers[_token][i].id20Spendable;
//                 burnSaver20 = 2000;
//                 burnSaver = burnSaver + burnSaver20;
//             }
//         }

//         burnSaver = burnSaver > ONE_HUNDRED_PERCENT
//             ? ONE_HUNDRED_PERCENT
//             : burnSaver;
//     }

//     function _transferCollectibles(
//         address _player,
//         uint256 _id,
//         uint256 _amount
//     ) internal {
//         collectiblesTransfer.safeTransferFrom(
//             collectibles,
//             _player,
//             devAddress,
//             _id,
//             _amount,
//             DEFAULT_MESSAGE
//         );
//     }

//     function getBurnedAmount(address _token)
//         external
//         view
//         override
//         returns (uint256)
//     {
//         return
//             burnedAmount[_token] +
//             (
//                 previousBurnManager != address(0)
//                     ? IAPWarsBurnManager(previousBurnManager).getBurnedAmount(
//                         _token
//                     )
//                     : 0
//             );
//     }

//     function getBurnRate(
//         address _farmManager,
//         address _token,
//         address _player,
//         uint256 _pid
//     ) external view override returns (uint16) {
//         uint16 burnRate = ONE_HUNDRED_PERCENT;

//         (
//             uint16 compoundBurnSaver,
            
//         ) = getCompundBurnSaverAndSpandablesIdsByPlayer(_token, _player);

//         // if (idSpandable10 != 0) {
//         //     _transferCollectibles(_player, idSpandable10, 1);
//         // }
//         // if (idSpandable15 != 0) {
//         //     _transferCollectibles(_player, idSpandable15, 1);
//         // }
//         // if (idSpandable20 != 0) {
//         //     _transferCollectibles(_player, idSpandable20, 1);
//         // }

//         if (compoundBurnSaver > burnRate) {
//             burnRate = 0;
//         } else {
//             burnRate -= compoundBurnSaver;
//         }

//         if (burnRate == ONE_HUNDRED_PERCENT) {
//             return ONE_HUNDRED_PERCENT - ONE_PERCENT;
//         } else {
//             return burnRate;
//         }
//     }

//     function manageAmount(
//         address _farmManager,
//         address _token,
//         address _player,
//         uint256 _pid,
//         uint256 _userAmount,
//         uint256 _burnAmount
//     ) external override {
//         IBEP20 token = IBEP20(_token);

//         if (!isBurnableToken(token)) {
//             token.transfer(devAddress, _burnAmount);
//         } else {
//             burn(_token);
//         }
//     }

//     function setCollectibles(ERC1155 _collectitles) public onlyOwner {
//         collectibles = _collectitles;
//     }

//     function getCollectibles() public view returns (ERC1155) {
//         return collectibles;
//     }

//     function burn(address _token) public override {
//         IAPWarsBaseToken token = IAPWarsBaseToken(_token);
//         uint256 amount = token.balanceOf(address(this));
//         token.burn(amount);

//         burnedAmount[_token] += amount;

//         BurnedAll(_token, amount);
//     }
// }
