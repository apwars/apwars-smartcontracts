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


contract('APWarsWorldManager.test', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;

  let wGOLDToken = null;
  let wLANDToken = null;
  let collectibles = null;
  let transfer = null;
  let transferMock = null;

  let worldManager = null;
  let worldMap = null;
  let landNFT = null;
  let worldNFT = null;
  let nftStorage = null;
  let tokenTransfer = null;


  it.only('should create a 100x100 map', async () => {

    const getContracts = contracts("bsctestnet");

    wGOLDToken = await APWarsGoldToken.at(getContracts.wGOLD);
    worldMap = await APWarsWorldMap.at("0xdD6e6826670E3eB8a93547a40ce445B08933A744");
    worldManager = await APWarsWorldManager.new();
    wLANDToken = await APWarsLandToken.at(getContracts.wLAND);
    transfer = await APWarsCollectiblesTransfer.at(getContracts.APWarsCollectiblesTransfer);
    // transferMock = await APWarsCollectiblesTransferMock.new();
    collectibles = await APWarsCollectibles.at(getContracts.APWarsCollectibles);

    landNFT = await APWarsBaseNFT.new('LAND', 'LAND', '');
    worldNFT = await APWarsBaseNFT.new('WORLD', 'WORLD', '');
    nftStorage = await APWarsBaseNFTStorage.new();
    worldTreasury = await APWarsWorldTreasury.new();
    tokenTransfer = await APWarsTokenTransfer.at(getContracts.APWarsTokenTransfer);
    eventHandler = await APWarsWorldManagerEventHandler.new();

    await worldNFT.mint(accounts[0]);

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`wLANDToken: ${wLANDToken.address}`);
    console.log(`landNFT: ${landNFT.address}`);
    console.log(`worldNFT: ${worldNFT.address}`);
    console.log(`nftStorage: ${nftStorage.address}`);
    console.log(`worldTreasury: ${worldTreasury.address}`);
    console.log(`worldMap: ${worldMap.address}`);

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await nftStorage.grantRole(await nftStorage.CONFIGURATOR_ROLE(), worldManager.address);

    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('1000000', 'ether'));
    await collectibles.setApprovalForAll(transfer.address, true);

    // await worldMap.setup(
    //   nftStorage.address,
    //   100,
    //   100,
    //   10
    // );

    // let region = 1;
    // let setupMapPromise = [];
    // for (let x = 0; x < 10; x++) {
    //   for (let y = 0; y < 10; y++) {
    //     console.log(`Setting up the region ${region} ${x}/${y}`);
    //     setupMapPromise.push(worldMap.setupMap(region, x, y));
    //     region++;
    //   }
    // }

    // await Promise.all(setupMapPromise);

    // console.log("Finish setupMapPromise");

    await worldManager.setup(
      worldNFT.address,
      landNFT.address,
      nftStorage.address,
      [38, 58, 59, 60, 61, 62],
      49,
      getContracts.devAddress,
      tokenTransfer.address,
      transfer.address,
      wLANDToken.address,
      collectibles.address,
      eventHandler.address
    );

    await worldManager.setWorldMap(1, worldMap.address);
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
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21
      ]);

    await worldManager.setPriceIncrementByFoundationType(
      1,
      [1, 38, 58, 59, 60, 61, 62,],
      [
        web3.utils.toWei('0.95', 'ether'),
        web3.utils.toWei('1.75', 'ether'),
        web3.utils.toWei('2.15', 'ether'),
        web3.utils.toWei('2.25', 'ether'),
        web3.utils.toWei('2.35', 'ether'),
        web3.utils.toWei('2.45', 'ether'),
        web3.utils.toWei('2.55', 'ether'),
      ]
    );

    const FOREST = 1;
    const STONE = 2;
    const BIG_MOUNTAIN = 3;
    const SAND = 4;
    const MOUNTAINS = 5;
    const TREES = 6;
    const RIVER = 7;

    function randomIntFromInterval(min, max) { // min and max included 
      return Math.floor(Math.random() * (max - min + 1) + min)
    }

    region = 1;
    // for (let x = 0; x < 10; x++) {
    //   for (let y = 0; y < 10; y++) {
    //     console.log(`Setting up special places ${region} ${x}/${y}`);
    //     const num = (x + y) % 3;
        
    //     switch (num) {
    //       case 0:
    //         console.log("0")
    //         await worldMap.setSpecialPlaces
    //         (
    //           [0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 2 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10)],
    //           [0 + (y * 10), 1 + (y * 10), 7 + (y * 10), 4 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 7 + (y * 10), 9 + (y * 10)] ,
    //           [FOREST, FOREST, STONE, BIG_MOUNTAIN, SAND, MOUNTAINS, MOUNTAINS, TREES, TREES, RIVER]
    //         );
    //         break;
    //       case 1:
    //         console.log("1")
    //         await worldMap.setSpecialPlaces
    //         (
    //           [0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10)],
    //           [9 + (y * 10), 3 + (y * 10), 9 + (y * 10), 9 + (y * 10), 2 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 4 + (y * 10)],
    //           [BIG_MOUNTAIN, RIVER, FOREST, FOREST, FOREST, FOREST, FOREST, BIG_MOUNTAIN, BIG_MOUNTAIN, TREES]
    //         );
    //         break;
    //       default:

    //         console.log("default")
    //         await worldMap.setSpecialPlaces
    //           (
    //             [0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10)],
    //             [9 + (y * 10), 3 + (y * 10), 9 + (y * 10), 9 + (y * 10), 2 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 4 + (y * 10)],
    //             [STONE, RIVER, FOREST, FOREST, RIVER, RIVER, FOREST, BIG_MOUNTAIN, BIG_MOUNTAIN, SAND]
    //           );
    //         break;
    //     }
    //     region++;
    //   }
    // }

    await worldManager.initializeWorldLandPricing(1, web3.utils.toWei('10', 'ether'));

    const x = await worldMap.getSpecialPlace(90, 90);
    const obj2 = await worldManager.getFoundationsByLands(1, 90, 90, 1);

    expect(x.toString()).to.be.equal('1');
    expect(obj2.types[0].toString()).to.be.equal('1');

    await worldManager.setNecessaryWorkersByFoundation(1,
      [1, 1, 1, 1, 1, 1],
      [38, 58, 59, 60, 61, 62],
      [20, 50, 25, 100, 15, 10]
    );

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`wLANDToken: ${wLANDToken.address}`);
    console.log(`landNFT: ${landNFT.address}`);
    console.log(`worldNFT: ${worldNFT.address}`);
    console.log(`nftStorage: ${nftStorage.address}`);
    console.log(`worldTreasury: ${worldTreasury.address}`);
    console.log(`worldMap: ${worldMap.address}`);


    console.log("finished");
  });
});