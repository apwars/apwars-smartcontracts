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

const contracts = require('../../../data/contracts');

const bscNetworking = "bsc";


contract('APWarsWorldManager.test', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;

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

  it('should create contracts and mint world', async () => {

    const getContracts = contracts(bscNetworking);

    worldMap = await APWarsWorldMap.new();
    worldManager = await APWarsWorldManager.new();
    wLANDToken = await APWarsLandToken.at(getContracts.wLAND);
    transfer = await APWarsCollectiblesTransfer.at(getContracts.APWarsCollectiblesTransfer);
    collectibles = await APWarsCollectibles.at(getContracts.APWarsCollectibles);

    landNFT = await APWarsBaseNFT.new('LAND', 'LAND', '');
    worldNFT = await APWarsBaseNFT.new('WORLD', 'WORLD', '');
    nftStorage = await APWarsBaseNFTStorage.new();
    tokenTransfer = await APWarsTokenTransfer.at(getContracts.APWarsTokenTransfer);
    eventHandler = await APWarsWorldManagerEventHandler.new();

    await worldNFT.mint(accounts[0]);

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await nftStorage.grantRole(await nftStorage.CONFIGURATOR_ROLE(), worldManager.address);

    // await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('1000000', 'ether'));
    // await collectibles.setApprovalForAll(transfer.address, true);

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`landNFT: ${landNFT.address}`);
    console.log(`worldNFT: ${worldNFT.address}`);
    console.log(`nftStorage: ${nftStorage.address}`);
    console.log(`worldMap: ${worldMap.address}`);
    console.log(`eventHandler: ${eventHandler.address}`);

    console.log("finished");
  });

  it.only('should create a 100x100 map', async () => {

    if (contractsWorld.worldMap === "") {
      console.log('worldMap empty')
      return;
    }

    worldMap = await APWarsWorldMap.at(contractsWorld.worldMap);

    await worldMap.setup(
      contractsWorld.nftStorage,
      100,
      100,
      10
    );

    let region = 1;
    for (let x = 0; x < 10; x++) {
      for (let y = 0; y < 10; y++) {
        console.log(`Setting up the region ${region} ${x}/${y}`);
        try {
          await worldMap.setupMap(region, x, y);
        } catch(error) {
          console.log(`Setting up the region ${region} ${x}/${y}`, error);
        }
        region++;
      }
    }

    console.log("Finish setupMapPromise");
  });

  it('should config setup world', async () => {

    const getContracts = contracts(bscNetworking);
    if (contractsWorld.worldMap === "") {
      console.log('worldMap empty')
      return;
    }

    worldManager = await APWarsWorldManager.at(contractsWorld.worldManager);

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

    console.log("Finish setup world");

  });

  it('should config worldMap setSpecialPlaces', async () => {

    if (contractsWorld.worldMap === "") {
      console.log('worldMap empty')
      return;
    }

    worldMap = await APWarsWorldMap.at(contractsWorld.worldMap);

    const FOREST = 1;
    const STONE = 2;
    const BIG_MOUNTAIN = 3;
    const SAND = 4;
    const MOUNTAINS = 5;
    const TREES = 6;
    const RIVER = 7;
    const LOCKED = 8;

    // function randomIntFromInterval(min, max) { // min and max included 
    //   return Math.floor(Math.random() * (max - min + 1) + min)
    // }

    region = 1;
    for (let x = 0; x < 10; x++) {
      for (let y = 0; y < 10; y++) {
        console.log(`Setting up special places ${region} ${x}/${y}`);
        const num = (x + y) % 3;

        //[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        //[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9] ,

        switch (num) {
          case 0:
            console.log("0")
            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 2 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10)],
                [0 + (y * 10), 1 + (y * 10), 7 + (y * 10), 4 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 7 + (y * 10), 9 + (y * 10)],
                [FOREST, FOREST, STONE, BIG_MOUNTAIN, SAND, MOUNTAINS, MOUNTAINS, TREES, TREES, RIVER]
              );

            // [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9],
            // [2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 8, 9, 0, 1, 2, 3, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 4, 5, 6, 8, 9, 0, 1, 2, 4, 5, 6, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8] ,


            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9],
                [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8],
                [LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED]
              );
            break;
          case 1:
            console.log("1")
            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10)],
                [9 + (y * 10), 3 + (y * 10), 9 + (y * 10), 9 + (y * 10), 2 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 4 + (y * 10)],
                [BIG_MOUNTAIN, RIVER, FOREST, FOREST, FOREST, FOREST, FOREST, BIG_MOUNTAIN, BIG_MOUNTAIN, TREES]
              );


            //75
            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9],
                [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8],
                [LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED]
              );
            break;
            break;
          default:

            console.log("default")
            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10)],
                [9 + (y * 10), 3 + (y * 10), 9 + (y * 10), 9 + (y * 10), 2 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 4 + (y * 10)],
                [STONE, RIVER, FOREST, FOREST, RIVER, RIVER, FOREST, BIG_MOUNTAIN, BIG_MOUNTAIN, SAND]
              );

            //74
            await worldMap.setSpecialPlaces
              (
                [0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9],
                [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8],
                [LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED]
              );
            break;
        }
        region++;
      }
    }

    console.log("Finish setup setSpecialPlaces");


  });
});