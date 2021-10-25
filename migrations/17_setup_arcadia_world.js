const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsGoldToken = artifacts.require('APWarsGoldToken');
const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsCollectiblesTransferMock = artifacts.require('APWarsCollectiblesTransferMock');

const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsWorldMap = artifacts.require('APWarsWorldMap');
const APWarsWorldManager = artifacts.require('APWarsWorldManager');
const APWarsBaseNFT = artifacts.require('APWarsBaseNFT');
const APWarsBaseNFTStorage = artifacts.require('APWarsBaseNFTStorage');
const APWarsWorldTreasury = artifacts.require('APWarsWorldTreasury');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');
const APWarsWorldManagerEventHandler = artifacts.require('APWarsWorldManagerEventHandler');

const contracts = require('../data/contracts');


let wLANDToken = null;
let collectibles = null;
let transfer = null;

let worldManager = null;
let worldMap = null;
let landNFT = null;
let worldNFT = null;
let nftStorage = null;
let tokenTransfer = null;

const contractsWorld = {
  worldManager: '0xfe40EEf0594664334847508901c802058B99215D',
  landNFT: '0x8ff595DE2e08731F5Fd6faE8b24A4aEE4B7c98A6',
  worldNFT: '0x0d40F1119672F129D6E8e41A42453d3baD6eA537',
  nftStorage: '0x46886e61fA6A596ad48Ac11A53288112C8233Dfa',
  worldMap: '0xF22E30a30065EA5597739D77c2c424e53616e516',
  eventHandler: '0x6F2735d5AA7E546e6384C80ae5Dd065E7C42910C',
}

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);

  landNFT = await APWarsBaseNFT.at(contractsWorld.landNFT);
  transfer = await APWarsCollectiblesTransfer.at(getContracts.APWarsCollectiblesTransfer);
  tokenTransfer = await APWarsTokenTransfer.at(getContracts.APWarsTokenTransfer);
  nftStorage = await APWarsBaseNFTStorage.at(contractsWorld.nftStorage);
  
  await deployer.deploy(APWarsWorldManager);
  const worldManager = await APWarsWorldManager.deployed();

  console.log(`worldManager: ${worldManager.address}`);

  await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
  await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
  await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
  await nftStorage.grantRole(await nftStorage.CONFIGURATOR_ROLE(), worldManager.address);

  await worldManager.setup(
    contractsWorld.worldNFT,
    contractsWorld.landNFT,
    contractsWorld.nftStorage,
    [38, 58, 59, 60, 61, 62],
    49,
    getContracts.devAddress, // warning: add dead address
    getContracts.APWarsTokenTransfer,
    getContracts.APWarsCollectiblesTransfer,
    getContracts.wLAND,
    getContracts.APWarsCollectibles,
    contractsWorld.eventHandler
  );

  await worldManager.setWorldMap(1, contractsWorld.worldMap);
  await worldManager.setWorldTreasury(1, getContracts.devAddress);

  await worldManager.setFoundationBuildingInterval(1,
    [
      1,
      1,
      1,
      1,
      1,
      1,
      38,
      58,
      59,
      60,
      61,
      62,
    ],
    [
      38,
      58,
      59,
      60,
      61,
      62,
      1,
      1,
      1,
      1,
      1,
      1,
    ],
    [
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      864000,
      604800
    ]);

  await worldManager.setPriceIncrementByFoundationType(
    1,
    [1, 38, 58, 59, 60, 61, 62,],
    [
      web3.utils.toWei('0.1', 'ether'),
      web3.utils.toWei('5', 'ether'),
      web3.utils.toWei('5', 'ether'),
      web3.utils.toWei('2.5', 'ether'),
      web3.utils.toWei('15', 'ether'),
      web3.utils.toWei('0.5', 'ether'),
      web3.utils.toWei('0.15', 'ether'),
    ]
  );

  await worldManager.initializeWorldLandPricing(1, web3.utils.toWei('10', 'ether'));

  await worldManager.setNecessaryWorkersByFoundation(1,
    [1, 1, 1, 1, 1, 1],
    [38, 58, 59, 60, 61, 62],
    [20, 50, 25, 100, 15, 10]
  );

  console.log(`worldManager: ${worldManager.address}`);
  console.log("Finish setup world");

};
