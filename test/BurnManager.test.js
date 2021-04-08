const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');

contract('BurnManager', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let burnManager = null;
  let collectibles = null;

  it('should setup collectibles and burn manager', async () => {
    burnManager = await APWarsBurnManager.new();
    collectibles = await APWarsCollectibles.new("URI");

    await collectibles.mint(accounts[1], 0, 1, '0x0');
    await collectibles.mint(accounts[2], 1, 1, '0x0');
    await collectibles.mint(accounts[3], 2, 1, '0x0');

    await burnManager.setGoldSaverConfig(0, 1000);
    await burnManager.setGoldSaverConfig(1, 4000);
    await burnManager.setGoldSaverConfig(2, 5000);

    await burnManager.setCollectibles(collectibles.address);

    const burnRateAccount0 = await burnManager.getBurnRate(accounts[0], accounts[0], 0);
    const burnRateAccount1 = await burnManager.getBurnRate(accounts[0], accounts[1], 0);
    const burnRateAccount2 = await burnManager.getBurnRate(accounts[0], accounts[2], 0);
    const burnRateAccount3 = await burnManager.getBurnRate(accounts[0], accounts[3], 0);

    expect(burnRateAccount0.toString()).to.be.equal('10000');
    expect(burnRateAccount1.toString()).to.be.equal('9000');
    expect(burnRateAccount2.toString()).to.be.equal('6000');
    expect(burnRateAccount3.toString()).to.be.equal('5000');

    await collectibles.safeTransferFrom(accounts[1], accounts[0], 0, 1, '0x0', {from: accounts[1]});
    await collectibles.safeTransferFrom(accounts[2], accounts[0], 1, 1, '0x0', {from: accounts[2]});
    await collectibles.safeTransferFrom(accounts[3], accounts[0], 2, 1, '0x0', {from: accounts[3]});
    
    const newBurnRateAccount0 = await burnManager.getBurnRate(accounts[0], accounts[0], 0);

    expect(newBurnRateAccount0.toString()).to.be.equal('0');
  });
});