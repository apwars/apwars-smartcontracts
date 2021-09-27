const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsCollectiblesTransferMock = artifacts.require('APWarsCollectiblesTransferMock');

const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsWorldMap = artifacts.require('APWarsWorldMap');
const APWarsBaseNFT = artifacts.require('APWarsBaseNFT');
const APWarsBaseNFTStorage = artifacts.require('APWarsBaseNFTStorage');
const APWarsWorldTreasury = artifacts.require('APWarsWorldTreasury');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');

contract('APWarsCollectiblesTransfer.test', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;

  let wGOLDToken = null;
  let worldMap = null;
  let wLANDToken = null;
  let collectibles = null;
  let transfer = null;
  let transferMock = null;

  let landNFT = null;
  let worldNFT = null;
  let nftStorage = null;
  let tokenTransfer = null;

  it('should transfer', async () => {
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    worldMap = await APWarsWorldMap.new();
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

    await landNFT.grantRole(await landNFT.MINTER_ROLE(), worldMap.address);
    await tokenTransfer.grantRole(await tokenTransfer.TRANSFER_ROLE(), worldMap.address);

    await worldMap.setup(
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

    let region = 1;
    for (let x = 0; x < 2; x++) {
      for (let y = 0; y < 2; y++) {
        await worldMap.setupMap(0, region, x, y, 2, web3.utils.toWei('10', 'ether'))
        region++;
      }
    }

    await wLANDToken.transfer(accounts[1], web3.utils.toWei('100', 'ether'));
    await wLANDToken.approve(tokenTransfer.address, web3.utils.toWei('100', 'ether'), {from: accounts[1]});
    await worldMap.buyLand(0, 0, 0, {from: accounts[1]});
  });
});