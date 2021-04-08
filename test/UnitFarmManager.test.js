const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsUnitFarmManager = artifacts.require('APWarsUnitFarmManager');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');

contract.only('UnitFarmManager', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let wGOLDToken = null;
  let wARCHER = null;
  let unitFarmManager = null;
  let burnManager = null;
  let collectibles = null;

  it('should setup tokens and farm manager', async () => {
    const currentBlock = await web3.eth.getBlockNumber();

    collectibles = await APWarsCollectibles.new("URI");
    wGOLDToken = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    wARCHER = await APWarsBaseToken.new('wARCHER', 'wARCHER');
    burnManager = await APWarsBurnManager.new();
    unitFarmManager = await APWarsUnitFarmManager.new(accounts[0], burnManager.address, currentBlock);

    await collectibles.mint(accounts[1], 0, 1, '0x0');
    await collectibles.mint(accounts[2], 1, 1, '0x0');
    await collectibles.mint(accounts[3], 2, 1, '0x0');
    await collectibles.mint(accounts[4], 3, 1, '0x0');

    await burnManager.setGoldSaverConfig(0, 1000); //90% burn rate
    await burnManager.setGoldSaverConfig(1, 4000); //60% burn rate
    await burnManager.setGoldSaverConfig(2, 5000); //50% burn rate
    await burnManager.setGoldSaverConfig(3, 10000); //0% burn rate
    await burnManager.setBaseToken(wGOLDToken.address);

    await burnManager.setCollectibles(collectibles.address);

    await Promise.all(
      [
        wGOLDToken,
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );

    await wGOLDToken.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.25).toString(), 'ether')); 
    await wGOLDToken.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.25).toString(), 'ether')); 
    await wGOLDToken.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.25).toString(), 'ether')); 
    await wGOLDToken.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.25).toString(), 'ether')); 

    await wGOLDToken.approve(unitFarmManager.address, await wGOLDToken.balanceOf(accounts[1]), { from: accounts[1] }); 
    await wGOLDToken.approve(unitFarmManager.address, await wGOLDToken.balanceOf(accounts[2]), { from: accounts[2] });
    await wGOLDToken.approve(unitFarmManager.address, await wGOLDToken.balanceOf(accounts[3]), { from: accounts[3] });
    await wGOLDToken.approve(unitFarmManager.address, await wGOLDToken.balanceOf(accounts[4]), { from: accounts[4] });

    await wARCHER.transferOwnership(unitFarmManager.address);

    await unitFarmManager.add(wARCHER.address,
      web3.utils.toWei('1', 'ether'),
      1000,
      wGOLDToken.address,
      burnManager.address,
      true
    );

    const totalSupply = await wGOLDToken.totalSupply();
    expect(totalSupply.toString()).to.be.equal('10000000000000000000000000');

    await unitFarmManager.deposit(0, await wGOLDToken.balanceOf(accounts[1]), { from: accounts[1] }); 
    await unitFarmManager.deposit(0, await wGOLDToken.balanceOf(accounts[2]), { from: accounts[2] }); 
    await unitFarmManager.deposit(0, await wGOLDToken.balanceOf(accounts[3]), { from: accounts[3] });
    await unitFarmManager.deposit(0, await wGOLDToken.balanceOf(accounts[4]), { from: accounts[4] }); 

    const totalSupplyAfterBurn = await wGOLDToken.totalSupply();
    expect(totalSupplyAfterBurn.toString()).to.be.equal('5000000000000000000000000');

    expect((await wGOLDToken.balanceOf(accounts[1])).toString()).to.be.equal('0');
    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('0');
    expect((await wGOLDToken.balanceOf(accounts[3])).toString()).to.be.equal('0');
    expect((await wGOLDToken.balanceOf(accounts[4])).toString()).to.be.equal('0');

    let account1Amount = await unitFarmManager.getUserAmount(0, accounts[1]);
    let account2Amount = await unitFarmManager.getUserAmount(0, accounts[2]);
    let account3Amount = await unitFarmManager.getUserAmount(0, accounts[3]);
    let account4Amount = await unitFarmManager.getUserAmount(0, accounts[4]);

    expect(account1Amount.toString()).to.be.equal('250000000000000000000000');
    expect(account2Amount.toString()).to.be.equal('1000000000000000000000000');
    expect(account3Amount.toString()).to.be.equal('1250000000000000000000000');
    expect(account4Amount.toString()).to.be.equal('2500000000000000000000000');

    await unitFarmManager.withdraw(0, account1Amount, { from: accounts[1] }); 
    await unitFarmManager.withdraw(0, account2Amount, { from: accounts[2] }); 
    await unitFarmManager.withdraw(0, account3Amount, { from: accounts[3] }); 
    await unitFarmManager.withdraw(0, account4Amount, { from: accounts[4] }); 

    expect((await wGOLDToken.balanceOf(accounts[1])).toString()).to.be.equal('250000000000000000000000');
    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('1000000000000000000000000');
    expect((await wGOLDToken.balanceOf(accounts[3])).toString()).to.be.equal('1250000000000000000000000');
    expect((await wGOLDToken.balanceOf(accounts[4])).toString()).to.be.equal('2500000000000000000000000');

    account1Amount = await unitFarmManager.getUserAmount(0, accounts[1]);
    account2Amount = await unitFarmManager.getUserAmount(0, accounts[2]);
    account3Amount = await unitFarmManager.getUserAmount(0, accounts[3]);
    account4Amount = await unitFarmManager.getUserAmount(0, accounts[4]);

    expect(account1Amount.toString()).to.be.equal('0');
    expect(account2Amount.toString()).to.be.equal('0');
    expect(account3Amount.toString()).to.be.equal('0');
    expect(account4Amount.toString()).to.be.equal('0');
  });
});