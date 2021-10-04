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

  it('should create a 100x100 map', async () => {
    const getContracts = contracts("bsctestnet");

    wGOLDToken = await APWarsGoldToken.at(getContracts.wGOLD);
    worldMap = await APWarsWorldMap.at("0x01ac5c9dcf69687bfcf6863ba46ffecb44ff50a2");
    worldManager = await APWarsWorldManager.new();
    wLANDToken = await APWarsLandToken.at(getContracts.wLAND);
    transfer = await APWarsCollectiblesTransfer.at(getContracts.APWarsCollectiblesTransfer);
    transferMock = await APWarsCollectiblesTransferMock.new();
    collectibles = await APWarsCollectibles.at(getContracts.APWarsCollectibles);

    landNFT = await APWarsBaseNFT.new('LAND', 'LAND', '');
    worldNFT = await APWarsBaseNFT.new('WORLD', 'WORLD', '');
    nftStorage = await APWarsBaseNFTStorage.new();
    worldTreasury = await APWarsWorldTreasury.new();
    tokenTransfer = await APWarsTokenTransfer.at(getContracts.APWarsTokenTransfer);
      
    // await collectibles.mint(accounts[0], 10, 100, '0x0');
    // await collectibles.mint(accounts[0], 20, 100, '0x0');
    // await collectibles.mint(accounts[0], 21, 100, '0x0');
    // await collectibles.mint(accounts[0], 22, 100, '0x0');
    // await collectibles.mint(accounts[0], 23, 100, '0x0');
    // await collectibles.mint(accounts[0], 24, 100, '0x0');
    // await collectibles.mint(accounts[0], 25, 100, '0x0');

    await worldNFT.mint(accounts[0]);

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

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`landNFT: ${landNFT.address}`);
    console.log(`worldNFT: ${worldNFT.address}`);
    console.log(`nftStorage: ${nftStorage.address}`);
    console.log(`worldTreasury: ${worldTreasury.address}`);
    console.log(`worldMap: ${worldMap.address}`);

    await worldManager.setup(
      worldMap.address,
      worldNFT.address,
      landNFT.address,
      nftStorage.address,
      [20, 21, 22, 23, 24, 25],
      49,
      getContracts.devAddress,
      tokenTransfer.address,
      transfer.address,
      wLANDToken.address,
      collectibles.address,
      worldTreasury.address
    );

    await worldManager.setBasePrice(1, web3.utils.toWei('10', 'ether'));
    await worldManager.setPriceIncrementByFoundationType(1, [0], [web3.utils.toWei('.95', 'ether')]);

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`landNFT: ${landNFT.address}`);
    console.log(`worldNFT: ${worldNFT.address}`);
    console.log(`nftStorage: ${nftStorage.address}`);
    console.log(`worldTreasury: ${worldTreasury.address}`);
    console.log(`worldMap: ${worldMap.address}`);


    console.log("finished");
  });
});