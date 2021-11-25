const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');

const APWarsTreasureHunt = artifacts.require('APWarsTreasureHunt');
const APWarsTreasureHuntEventHandler = artifacts.require('APWarsTreasureHuntEventHandler');
const APWarsTreasureHuntSetup = artifacts.require('APWarsTreasureHuntSetup');

let treasureHunt;
let treasureHuntEventHandler;
let treasureHuntSetup;

const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  // if (process.env.SKIP_MIGRATION === 'true') {
  //   return;
  // }

  const getContracts = contracts(network);

  const blockNumber = await web3.eth.getBlockNumber();
  treasureHunt = await APWarsTreasureHunt.at('0x07ebef3047bb83d6ca6e3a0f921cbccc89c01b42');
  treasureHuntEventHandler = await APWarsTreasureHuntEventHandler.at('0x4c54ae58b91a5a5d07a48930d0e3de4e0c0baff2');
  treasureHuntSetup = await APWarsTreasureHuntSetup.at('0x5f735e8148D4CbBf7933B18bCB91657482EdB566');

  const tokenTransfer = await APWarsTokenTransfer.at(getContracts.APWarsTokenTransfer);
  const transfer = await APWarsCollectiblesTransfer.at(getContracts.APWarsCollectiblesTransfer);

  await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), treasureHuntSetup.address);
  await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), treasureHuntSetup.address);

  await treasureHuntSetup.grantRole(await treasureHuntSetup.TREASURE_HUNT_ROLE(), treasureHunt.address);

  await treasureHuntSetup.setup(
    getContracts.wLAND,
    getContracts.APWarsCollectibles,
    getContracts.APWarsTokenTransfer,
    getContracts.APWarsCollectiblesTransfer,
    getContracts.devAddress2,
    getContracts.worldManager,
    10000,
    10000,
    49,
    1000,
    web3.utils.toWei('0.1', 'ether'),
    10
  );

  console.log(`treasureHunt: ${treasureHunt.address}`);
  const endTreasureHunt = 57600;

  // await treasureHunt.setup(treasureHuntEventHandler.address);
  await treasureHunt.updateTreasureHunt(
    1,
    1,
    parseInt(blockNumber.toString()) + endTreasureHunt,
    treasureHuntSetup.address,
    5
  );

  console.log('treasureHunt', treasureHunt.address);
  console.log('treasureHuntSetup', treasureHuntSetup.address);
  console.log('treasureHuntEventHandler', treasureHuntEventHandler.address);

  console.log("finished");
};
