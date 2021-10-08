const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsCollectiblesTransferMock = artifacts.require('APWarsCollectiblesTransferMock');

const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsWorldMap = artifacts.require('APWarsWorldMap');
const APWarsWorldManager = artifacts.require('APWarsWorldManager');
const APWarsBaseNFT = artifacts.require('APWarsBaseNFT');
const APWarsBaseNFTStorage = artifacts.require('APWarsBaseNFTStorage');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');
const APWarsWorldManagerEventHandler = artifacts.require('APWarsWorldManagerEventHandler');

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
  let eventHandler = null;

  it('should setup', async () => {
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    worldMap = await APWarsWorldMap.new();
    worldManager = await APWarsWorldManager.new();
    wLANDToken = await APWarsLandToken.new('wLAND', 'wLAND');
    burnManager = await APWarsBurnManager.new();
    transfer = await APWarsCollectiblesTransfer.new();
    transferMock = await APWarsCollectiblesTransferMock.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");

    landNFT = await APWarsBaseNFT.new('LAND', 'LAND', '');
    worldNFT = await APWarsBaseNFT.new('WORLD', 'WORLD', '');
    nftStorage = await APWarsBaseNFTStorage.new();
    tokenTransfer = await APWarsTokenTransfer.new();
    eventHandler = await APWarsWorldManagerEventHandler.new();
      
    await collectibles.mint(accounts[0], 10, 100, '0x0');
    await collectibles.mint(accounts[0], 20, 100, '0x0');
    await collectibles.mint(accounts[0], 21, 100, '0x0');
    await collectibles.mint(accounts[0], 22, 100, '0x0');
    await collectibles.mint(accounts[0], 23, 100, '0x0');
    await collectibles.mint(accounts[0], 24, 100, '0x0');
    await collectibles.mint(accounts[0], 25, 100, '0x0');

    await worldNFT.mint(accounts[0]);

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`wLANDToken: ${wLANDToken.address}`);

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await nftStorage.grantRole(await nftStorage.CONFIGURATOR_ROLE(), worldManager.address);

    await worldMap.setup(
      nftStorage.address,
      2,
      2,
      2
    );
    let region = 1;
    for (let x = 0; x < 2; x++) {
      for (let y = 0; y < 2; y++) {
        await worldMap.setupMap(region, x, y);
        region++;
      }
    }

    await worldManager.setup(
      worldNFT.address,
      landNFT.address,
      nftStorage.address,
      [20, 21, 22, 23, 24, 25],
      10,
      accounts[8],
      tokenTransfer.address,
      transfer.address,
      wLANDToken.address,
      collectibles.address,
      eventHandler.address
    );

    worldManager.setWorldMap(1, worldMap.address);
    worldManager.setWorldTreasury(1, accounts[8]);

    await worldManager.setFoundationBuildingInterval(1,
      [
        1,
        1,
        1,
        1,
        1,
        1,
        20,
        21,
        22,
        23,
        24,
        25,
      ],
      [
        20,
        21,
        22,
        23,
        24,
        25,
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
    
    
    await worldMap.setSpecialPlaces
    (
      [2],
      [2] ,
      [3]
    );

    const obj = await worldManager.getRawFoundationTypeByLand(1, 2, 2);
    const obj2 = await worldManager.getFoundationsByLands(1, 2, 2, 1);
    expect(obj.landType.toString()).to.be.equal('3');
    expect(obj.owner.toString()).to.be.equal('0x0000000000000000000000000000000000000000');
    expect(obj2.types[0].toString()).to.be.equal('3');
    expect(obj2.owners[0].toString()).to.be.equal('0x0000000000000000000000000000000000000000');
  });

  it('should approve contracts', async () => {
    await wLANDToken.transfer(accounts[1], web3.utils.toWei('100', 'ether'));
    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('1000000', 'ether'));
    
    await collectibles.setApprovalForAll(transfer.address, true, { from: accounts[1] });
    await collectibles.setApprovalForAll(transfer.address, true);
  });

  it('should setup pricing', async () => {
    await worldManager.initializeWorldLandPricing(1, web3.utils.toWei('10', 'ether'));
    const landPrice = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('10', 'ether'), "fail to check landPrice");

    await worldManager.setPriceIncrementByFoundationType(
      1,
      [1, 20, 21],
      [
        web3.utils.toWei('0.1', 'ether'),
        web3.utils.toWei('1', 'ether'),
        web3.utils.toWei('2', 'ether'),
      ]
    );
  });

  it('should buy a land and fail to buy again', async () => {
    const tokenId0 = await worldManager.getLandTokenId(1, 0, 0);
    const foundation0 = await worldManager.getRawFoundationTypeByLand(1, 0, 0);

    expect(foundation0[1].toString()).to.be.equal('0');
    expect(tokenId0.toString()).to.be.equal('0');

    try {
      await worldManager.buyLand(0, 0, 0, { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorldManager:INVALID_WORLD");
    }

    try {
      await worldManager.buyLand(1, 10, 10, { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorldManager:INVALID_LAND");
    }

    try {
      await worldManager.buyLand(1, 0, 0, { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorldManager:INVALID_WLAND_ALLOWANCE");
    }

    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('1000000', 'ether'), { from: accounts[1] });
    await worldManager.buyLand(1, 0, 0, { from: accounts[1] });

    const landPrice = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('10.1', 'ether'), "fail to check landPrice");

    const owner1 = await worldManager.getLandOwner(1, 0, 0);
    const tokenId1 = await worldManager.getLandTokenId(1, 0, 0);
    const foundation1 = await worldManager.getRawFoundationTypeByLand(1, 0, 0);

    expect(foundation1[1].toString()).to.be.equal('1');
    expect(foundation1.owner.toString()).to.be.equal(accounts[1]);
    expect(owner1).to.be.equal(accounts[1]);
    expect(tokenId1.toString()).to.be.equal('1');
    
    try {
      await worldManager.buyLand(1, 0, 0, { from: accounts[1] });
      throw {}; 
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsWorldManager:LAND_IS_OWNED');
    }
  });

  it('should buy a land, build and destroy a foundation', async () => {
    await worldManager.setFoundationBuildingInterval(1, [1, 20], [20, 1], [0, 0]);
    await worldManager.setNecessaryWorkersByFoundation(1, [1, 20], [20, 1], [1000, 5]);

    await worldManager.buyLand(1, 0, 1);

    const landPrice = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('10.2', 'ether'), "fail to check landPrice");

    const owner2 = await worldManager.getLandOwner(1, 0, 1);
    const tokenId2 = await worldManager.getLandTokenId(1, 0, 1);
    expect(tokenId2.toString()).to.be.equal('2');
    expect(owner2).to.be.equal(accounts[0]);

    try {
      await worldManager.buildFoundation(1, 0, 1, 20);
      throw {}; 
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsWorldManager:INVALID_WORKERS_BALANCE');
    }

    await worldManager.setNecessaryWorkersByFoundation(1, [1, 20], [20, 1], [10, 5]);
    await worldManager.buildFoundation(1, 0, 1, 20);
    await worldManager.destroyFoundation(1, 0, 1);

    const landPrice3 = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice3.toString()).to.be.equal(web3.utils.toWei('11.2', 'ether'), "fail to check landPrice");

    const workersBalance = await collectibles.balanceOf(accounts[0], 10);
    const villagesBalance = await collectibles.balanceOf(accounts[0], 20);
    expect(workersBalance.toString()).to.be.equal('85');
    expect(villagesBalance.toString()).to.be.equal('99');
  });

  it('should buy a land and build in one transaction', async () => {
    await worldManager.setNecessaryWorkersByFoundation(1, [1], [21], [1]);
    await worldManager.buyLandAndBuildFoundation(1, 1, 1, 21);

    const landPrice = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('13.3', 'ether'), "fail to check landPrice");

    const obj = await worldManager.getRawFoundationTypeByLand(1, 1, 1);
    expect(obj.oldValue.toString()).to.be.equal('1', 'fail to check oldValue');
    expect(obj.newValue.toString()).to.be.equal('21', 'fail to check newValue');
    console.log({ oldValue: obj.oldValue.toString(), newValue: obj.newValue.toString(), targetBlock: obj.targetBlock.toString() });

    const foundationType = await worldManager.getFoundationTypeByLand(1, 1, 1);
    expect(foundationType.toString()).to.be.equal('21');

    const workersBalance = await collectibles.balanceOf(accounts[0], 10);
    const villagesBalance = await collectibles.balanceOf(accounts[0], 21);

    expect(workersBalance.toString()).to.be.equal('84');
    expect(villagesBalance.toString()).to.be.equal('99');
  });

  it.skip('should create a 100x100 map', async () => {
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    worldMap = await APWarsWorldMap.new();
    worldManager = await APWarsWorldManager.new();
    wLANDToken = await APWarsLandToken.new('wLAND', 'wLAND');
    burnManager = await APWarsBurnManager.new();
    transfer = await APWarsCollectiblesTransfer.new();
    transferMock = await APWarsCollectiblesTransferMock.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");

    landNFT = await APWarsBaseNFT.new('LAND', 'LAND', '');
    worldNFT = await APWarsBaseNFT.new('WORLD', 'WORLD', '');
    nftStorage = await APWarsBaseNFTStorage.new();
    tokenTransfer = await APWarsTokenTransfer.new();
    eventHandler = await APWarsWorldManagerEventHandler.new();

    await collectibles.mint(accounts[0], 10, 100, '0x0');
    await collectibles.mint(accounts[0], 62, 100, '0x0');
    await collectibles.mint(accounts[0], 60, 100, '0x0');
    await collectibles.mint(accounts[0], 58, 100, '0x0');
    await collectibles.mint(accounts[0], 61, 100, '0x0');
    await collectibles.mint(accounts[0], 59, 100, '0x0');
    await collectibles.mint(accounts[0], 38, 100, '0x0');

    await worldNFT.mint(accounts[0]);

    console.log(`worldManager: ${worldManager.address}`);
    console.log(`wLANDToken: ${wLANDToken.address}`);

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await transfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
    await nftStorage.grantRole(await nftStorage.CONFIGURATOR_ROLE(), worldManager.address);

    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('1000000', 'ether'));
    await collectibles.setApprovalForAll(transfer.address, true);

    await worldMap.setup(
      nftStorage.address,
      100,
      100,
      10
    );

    let region = 1;
    for (let x = 0; x < 10; x++) {
      for (let y = 0; y < 10; y++) {
        console.log(`Setting up the region ${region} ${x}/${y}`);
        await worldMap.setupMap(region, x, y);
        region++;
      }
    }

    await worldManager.setup(
      worldNFT.address,
      landNFT.address,
      nftStorage.address,
      [62, 60, 58, 61, 59, 38],
      10,
      accounts[8],
      tokenTransfer.address,
      transfer.address,
      wLANDToken.address,
      collectibles.address,
      eventHandler.address
    );

    worldManager.setWorldMap(1, worldMap.address);
    worldManager.setWorldTreasury(1, accounts[8]);

    await worldManager.setFoundationBuildingInterval(1,
      [
        1,
        1,
        1,
        1,
        1,
        1,
        20,
        21,
        22,
        23,
        24,
        25,
      ],
      [
        20,
        21,
        22,
        23,
        24,
        25,
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
      [1, 20, 21, 22, 23, 24, 25,],
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
    const LOCKED = 8;

    function randomIntFromInterval(min, max) { // min and max included 
      return Math.floor(Math.random() * (max - min + 1) + min)
    }
    

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
              [0 + (y * 10), 1 + (y * 10), 7 + (y * 10), 4 + (y * 10), 2 + (y * 10), 3 + (y * 10), 7 + (y * 10), 3 + (y * 10), 7 + (y * 10), 9 + (y * 10)] ,
              [FOREST, FOREST, STONE, BIG_MOUNTAIN, SAND, MOUNTAINS, MOUNTAINS, TREES, TREES, RIVER]
            );

            // [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9],
            // [2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 8, 9, 0, 1, 2, 3, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 4, 5, 6, 8, 9, 0, 1, 2, 4, 5, 6, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8] ,
              

            await worldMap.setSpecialPlaces
            (
              [0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 0 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 1 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 2 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 3 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 4 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 5 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 6 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 7 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 8 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9 + (x * 10), 9],
              [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8] ,
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
              [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8] ,
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
              [2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 3 + (y * 10), 4 + (y * 10), 5 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 4 + (y * 10), 5 + (y * 10), 6 + (y * 10), 8 + (y * 10), 9 + (y * 10), 0 + (y * 10), 1 + (y * 10), 2 + (y * 10), 5 + (y * 10), 6 + (y * 10), 7 + (y * 10), 8] ,
              [LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED, LOCKED]
            );
            break;
        }
        region++;
      }
    }

    await worldManager.initializeWorldLandPricing(1, web3.utils.toWei('10', 'ether'));

    const x = await worldMap.getSpecialPlace(90, 90);
    const obj2 = await worldManager.getFoundationsByLands(1, 90, 90, 1);

    expect(x.toString()).to.be.equal('1');
    expect(obj2.types[0].toString()).to.be.equal('1');

    console.log("finished");
  });
});