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
const APWarsWorldTreasury = artifacts.require('APWarsWorldTreasury');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');

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
    worldTreasury = await APWarsWorldTreasury.new();
    tokenTransfer = await APWarsTokenTransfer.new();
      
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
      worldMap.address,
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
      worldTreasury.address
    );

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
        web3.utils.toWei('0.95', 'ether'),
        web3.utils.toWei('1.75', 'ether'),
        web3.utils.toWei('2.75', 'ether'),
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
      console.log(e);
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
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('10.95', 'ether'), "fail to check landPrice");

    const owner1 = await worldManager.getLandOwner(1, 0, 0);
    const tokenId1 = await worldManager.getLandTokenId(1, 0, 0);
    const foundation1 = await worldManager.getRawFoundationTypeByLand(1, 0, 0);

    expect(foundation1[1].toString()).to.be.equal('1');
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
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('11.90', 'ether'), "fail to check landPrice");

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
    expect(landPrice3.toString()).to.be.equal(web3.utils.toWei('13.65', 'ether'), "fail to check landPrice");

    const workersBalance = await collectibles.balanceOf(accounts[0], 10);
    const villagesBalance = await collectibles.balanceOf(accounts[0], 20);
    expect(workersBalance.toString()).to.be.equal('85');
    expect(villagesBalance.toString()).to.be.equal('99');
  });

  it('should buy a land and build in one transaction', async () => {
    await worldManager.setNecessaryWorkersByFoundation(1, [1], [21], [1]);
    await worldManager.buyLandAndBuildFoundation(1, 1, 1, 21);

    const landPrice = await worldManager.getLandPrice(1, 0, 0);
    expect(landPrice.toString()).to.be.equal(web3.utils.toWei('17.35', 'ether'), "fail to check landPrice");

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
    worldTreasury = await APWarsWorldTreasury.new();
    tokenTransfer = await APWarsTokenTransfer.new();
      
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
      worldMap.address,
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
      worldTreasury.address
    );

    await worldManager.initializeWorldLandPricing(1, web3.utils.toWei('10', 'ether'));
    await worldManager.setPriceIncrementByFoundationType(1, [0], [web3.utils.toWei('.95', 'ether')]);

    console.log("finished");
  });
});