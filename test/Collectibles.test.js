const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');

contract.only('BurnManager', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;

  let wGOLDToken = null;
  let collectibles = null;

  it('should mint using a signature', async () => {
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    burnManager = await APWarsBurnManager.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");
    await collectibles.setDevAddress(accounts[2]);

    await Promise.all(
      [
        wGOLDToken,
      ].map(token => token.mint(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );

    //creating a validator signature
    const hash = await collectibles.hashClaim(wGOLDToken.address, 0, '100000000000000000');
    const signature = await web3.eth.sign(hash, accounts[0]);

    const balanceBeforeClaim = await collectibles.balanceOf(accounts[1], 0);
    expect(balanceBeforeClaim.toString()).to.be.equal('0');

    await wGOLDToken.approve(collectibles.address, '1000000000000000000', { from: accounts[1] });
    await collectibles.setMaxSupply(0, 10);
    await collectibles.claim(wGOLDToken.address, 0, '100000000000000000', signature, { from: accounts[1] });
    await collectibles.claim(wGOLDToken.address, 0, '100000000000000000', signature, { from: accounts[1] });

    const balanceAfterClaim = await collectibles.balanceOf(accounts[1], 0);
    expect(balanceAfterClaim.toString()).to.be.equal('2');
  });
});