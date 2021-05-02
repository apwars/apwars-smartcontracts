const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');

contract('BurnManager', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let burnManager = null;
  let collectibles = null;

  it('should setup collectibles and burn manager', async () => {
    burnManager = await APWarsBurnManager.new(accounts[2]);
    wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    wARCHER = await APWarsBaseToken.new('wARCHER', 'wARCHER');
    collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');

    const fakeFarmManager = accounts[0];

    await wGOLD.mint(burnManager.address, '1000000');
    await wARCHER.mint(burnManager.address, '1000000');

    await collectibles.mint(accounts[1], 7, 1, '0x0');
    await collectibles.mint(accounts[2], 10, 1, '0x0');
    await collectibles.mint(accounts[3], 11, 1, '0x0');

    await burnManager.setBurnSaverAmount(wGOLD.address, 7, 1000);
    await burnManager.setBurnSaverAmount(wGOLD.address, 10, 4000);
    await burnManager.setBurnSaverAmount(wARCHER.address, 11, 5000);

    expect((await burnManager.getBurnSaverAmount(wGOLD.address, 7)).toString()).to.be.equal('1000', 'fail to check burn saver 7');
    expect((await burnManager.getBurnSaverAmount(wGOLD.address, 10)).toString()).to.be.equal('4000', 'fail to check burn saver 10');
    expect((await burnManager.getBurnSaverAmount(wGOLD.address, 11)).toString()).to.be.equal('0', 'fail to check burn saver 11');
    expect((await burnManager.getBurnSaverAmount(wARCHER.address, 11)).toString()).to.be.equal('5000', 'fail to check burn saver 11');

    await burnManager.setCollectibles(collectibles.address);

    const burnRateAccount0 = await burnManager.getBurnRate(fakeFarmManager, wGOLD.address, accounts[0], 0);
    const burnRateAccount1 = await burnManager.getBurnRate(fakeFarmManager, wGOLD.address, accounts[1], 0);
    const burnRateAccount2 = await burnManager.getBurnRate(fakeFarmManager, wGOLD.address, accounts[2], 0);
    const burnRateAccount3 = await burnManager.getBurnRate(fakeFarmManager, wGOLD.address, accounts[3], 0);

    expect(burnRateAccount0.toString()).to.be.equal('9900', 'fail to check #account 0');
    expect(burnRateAccount1.toString()).to.be.equal('9000', 'fail to check #account 1');
    expect(burnRateAccount2.toString()).to.be.equal('6000', 'fail to check #account 2');
    expect(burnRateAccount3.toString()).to.be.equal('9900', 'fail to check #account 3');

    await collectibles.safeTransferFrom(accounts[1], accounts[0], 7, 1, '0x0', {from: accounts[1]});
    await collectibles.safeTransferFrom(accounts[2], accounts[0], 10, 1, '0x0', {from: accounts[2]});
    await collectibles.safeTransferFrom(accounts[3], accounts[0], 11, 1, '0x0', {from: accounts[3]});
    
    const newBurnRateAccount0 = await burnManager.getBurnRate(fakeFarmManager, wGOLD.address, accounts[0], 0);

    expect(newBurnRateAccount0.toString()).to.be.equal('5000');

    await burnManager.setBurnableToken(wGOLD.address, true);
    await burnManager.setBurnableToken(wARCHER.address, false);

    expect(await burnManager.isBurnableToken(wGOLD.address)).to.be.true;
    expect(await burnManager.isBurnableToken(wARCHER.address)).to.be.false;

    expect((await wGOLD.balanceOf(burnManager.address)).toString()).to.be.equal('1000000', 'fail to check burnManager balance of wGOLD');
    expect((await wARCHER.balanceOf(burnManager.address)).toString()).to.be.equal('1000000', 'fail to check burnManager balance of wARCHER');

    await burnManager.manageAmount(fakeFarmManager, wGOLD.address, accounts[0], 0, 1000000, 1000000);
    await burnManager.manageAmount(fakeFarmManager, wARCHER.address, accounts[0], 0, 1000000, 1000000);

    const wGOLDTotalSupply = await wGOLD.totalSupply();
    const wARCHERTotalSupply = await wARCHER.totalSupply();
    
    expect(wGOLDTotalSupply.toString()).to.be.equal('0');
    expect(wARCHERTotalSupply.toString()).to.be.equal('1000000');
  });
});