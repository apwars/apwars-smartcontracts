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
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);

  const blockNumber = await web3.eth.getBlockNumber();
  treasureHunt = await APWarsTreasureHunt.new();
  treasureHuntEventHandler = await APWarsTreasureHuntEventHandler.new();
  treasureHuntSetup = await APWarsTreasureHuntSetup.new();

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
    getContracts.feeAddress,
    getContracts.worldManager,
    5000,
    5000,
    49,
    1000,
    web3.utils.toWei('0.1', 'ether'),
    10
  );

  console.log(`treasureHunt: ${treasureHunt.address}`);
  const endTreasureHunt = 57600;

  await treasureHunt.setup(treasureHuntEventHandler.address);
  await treasureHunt.addTreasureHunt(
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
