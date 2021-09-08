const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsCollectiblesTransferMock = artifacts.require('APWarsCollectiblesTransferMock');

contract('APWarsCollectiblesTransfer.test', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;

  let wGOLDToken = null;
  let collectibles = null;
  let transfer = null;
  let transferMock = null;

  it('should transfer', async () => {
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    burnManager = await APWarsBurnManager.new();
    transfer = await APWarsCollectiblesTransfer.new();
    transferMock = await APWarsCollectiblesTransferMock.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");
      
    await collectibles.mint(accounts[0], 10, 100, '0x0');

    await collectibles.setApprovalForAll(transfer.address, true);

    await transfer.grantRole(await transfer.TRANSFER_ROLE(), transferMock.address);
    await transferMock.safeTransferFrom(transfer.address, collectibles.address, accounts[0], accounts[1], 10, 1, '0x0');
  });
});