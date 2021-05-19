const Collectibles = artifacts.require('APWarsCollectibles');
const BurnManager = artifacts.require('APWarsBurnManagerV2');
const CollectiblesDisperser = artifacts.require('APWarsCollectiblesDisperser');

contract('APWarsCollectiblesDisperser', accounts => {
  it('should mint do a batched transfer', async () => {
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");
    const disperser = await CollectiblesDisperser.new();

    await collectibles.mint(accounts[0], 1, 100, '0x0');
    await collectibles.mint(accounts[0], 2, 100, '0x0');
    await collectibles.mint(accounts[0], 3, 100, '0x0');
    await collectibles.mint(accounts[0], 4, 100, '0x0');
    await collectibles.setApprovalForAll(disperser.address, true);

    for (let i = 1; i < accounts.length; i++) {
      expect((await collectibles.balanceOf(accounts[1], 1)).toString()).to.be.equal('0');
      expect((await collectibles.balanceOf(accounts[1], 2)).toString()).to.be.equal('0');
      expect((await collectibles.balanceOf(accounts[1], 3)).toString()).to.be.equal('0');
      expect((await collectibles.balanceOf(accounts[1], 4)).toString()).to.be.equal('0');
    }

    await disperser.batchTransfer(collectibles.address, accounts, 1, 1, '0x0');

    for (let i = 1; i < accounts.length; i++) {
      expect((await collectibles.balanceOf(accounts[1], 1)).toString()).to.be.equal('1');
    }

    await disperser.batchTransferMultiple(collectibles.address, [accounts[1], accounts[2], accounts[3]], [2, 3, 4], [3, 2, 1], '0x0');
    
    expect((await collectibles.balanceOf(accounts[1], 2)).toString()).to.be.equal('3');
    expect((await collectibles.balanceOf(accounts[2], 3)).toString()).to.be.equal('2');
    expect((await collectibles.balanceOf(accounts[3], 4)).toString()).to.be.equal('1');
  });
});