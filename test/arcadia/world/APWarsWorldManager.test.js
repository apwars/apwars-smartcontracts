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

  it('should transfer', async () => {
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

    await worldNFT.mint(accounts[0]);

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldManager.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldManager.address);
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
      [10],
      accounts[8],
      tokenTransfer.address,
      wLANDToken.address,
      collectibles.address,
      worldTreasury.address
    );

    await worldManager.setBasePrice(1, web3.utils.toWei('10', 'ether'));
    await worldManager.setPriceIncrementByFoundationType(1, [0], [web3.utils.toWei('.95', 'ether')]);

    const varName0 = await worldManager.getLandVarName(0, 0);
    const owner0 = await worldManager.getLandOwner(1, 0, 0);
    const tokenId0 = await worldManager.getLandTokenId(1, 0, 0);
    console.log({ varName0, owner0, tokenId0: tokenId0.toString() });

    await wLANDToken.transfer(accounts[1], web3.utils.toWei('100', 'ether'));
    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('100', 'ether'), {from: accounts[1]});
    await worldManager.buyLand(1, 0, 0, { from: accounts[1] });

    const varName1 = await worldManager.getLandVarName(0, 0);
    const owner1 = await worldManager.getLandOwner(1, 0, 0);
    const tokenId1 = await worldManager.getLandTokenId(1, 0, 0);
    console.log({ varName1, owner1, tokenId1: tokenId1.toString() });
    
    try {
      await worldManager.buyLand(1, 0, 0, { from: accounts[1] });
      throw {}; 
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsWorldManager:LAND_IS_OWNED');
    }

    await worldManager.buyLand(0, 0, 1, { from: accounts[1] });
  });
});