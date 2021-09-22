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

    try {
      await transferMock.safeTransferFrom(transfer.address, collectibles.address, accounts[0], accounts[1], 10, 1, '0x0');
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCollectiblesTransfer: INVALID_ROLE");
    }

    await transfer.grantRole(await transfer.TRANSFER_ROLE(), transferMock.address);
    await transferMock.safeTransferFrom(transfer.address, collectibles.address, accounts[0], accounts[1], 10, 1, '0x0');

    try {
      await transferMock.safeTransferFrom(transfer.address, collectibles.address, accounts[0], accounts[1], 10, 1, '0x0', { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("_from != tx.origin");
    }
  });
});