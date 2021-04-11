const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsGoldToken = artifacts.require('APWarsGoldToken');
const APWarsUnitFarmManager = artifacts.require('APWarsUnitFarmManager');
const APWarsBurnManagerMOCK = artifacts.require('APWarsBurnManagerMOCK');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');

contract('UnitFarmManager > Collectible burning rules', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let wGOLDToken = null;
  let wARCHER = null;
  let unitFarmManager = null;
  let burnManager = null;
  let collectibles = null;

  it('setup', async () => {
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

    const account1PendingTokens = await unitFarmManager.pendingTokens(0, accounts[1]);
    const account2PendingTokens = await unitFarmManager.pendingTokens(0, accounts[2]);
    const account3PendingTokens = await unitFarmManager.pendingTokens(0, accounts[3]);
    const account4PendingTokens = await unitFarmManager.pendingTokens(0, accounts[4]);

    console.log({
      account1PendingTokens: account1PendingTokens.toString(),
      account2PendingTokens: account2PendingTokens.toString(),
      account3PendingTokens: account3PendingTokens.toString(),
      account4PendingTokens: account4PendingTokens.toString(),
    })

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

contract('UnitFarmManager > Mocked burning rules', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let wGOLDToken = null;
  let wARCHER = null;
  let unitFarmManager = null;
  let burnManager = null;

  it('should setup tokens and farm manager', async () => {
    const currentBlock = await web3.eth.getBlockNumber();
    wGOLDToken = await APWarsGoldToken.new('wGOLD', 'wGOLD');
    wARCHER = await APWarsBaseToken.new('wARCHER', 'wARCHER');
    wWARRIOR = await APWarsBaseToken.new('wWARRIOR', 'wWARRIOR');
    burnManager = await APWarsBurnManagerMOCK.new();
    unitFarmManager = await APWarsUnitFarmManager.new(accounts[0], currentBlock);

    await Promise.all(
      [
        wGOLDToken,
        wARCHER,
      ].map(token => token.mint(accounts[0], UNIT_DEFAULT_SUPPLY))
    );

    await wGOLDToken.transfer(accounts[2], 1000);
    await wGOLDToken.transfer(accounts[3], 2000);
    await wGOLDToken.transfer(accounts[4], 3000);

    await wGOLDToken.approve(unitFarmManager.address, 1000, { from: accounts[2] });
    await wGOLDToken.approve(unitFarmManager.address, 2000, { from: accounts[3] });
    await wGOLDToken.approve(unitFarmManager.address, 3000, { from: accounts[4] });

    await wARCHER.transferOwnership(unitFarmManager.address);
    await wWARRIOR.transferOwnership(unitFarmManager.address);

    await unitFarmManager.add(wARCHER.address,
      1,
      1000,
      wGOLDToken.address,
      burnManager.address,
      true
    );

    await unitFarmManager.add(wWARRIOR.address,
      2,
      2000,
      wGOLDToken.address,
      burnManager.address,
      true
    );

    await burnManager.setBurnRate(accounts[2], 0);
    await burnManager.setBurnRate(accounts[3], 0);
    await burnManager.setBurnRate(accounts[4], 0);

    const totalSupply = await wGOLDToken.totalSupply();
    expect(totalSupply.toString()).to.be.equal(UNIT_DEFAULT_SUPPLY.toString());

    await unitFarmManager.deposit(0, 500, { from: accounts[2] });
    await unitFarmManager.deposit(0, 600, { from: accounts[3] });
    await unitFarmManager.deposit(0, 700, { from: accounts[4] });

    await unitFarmManager.deposit(1, 100, { from: accounts[2] });
    await unitFarmManager.deposit(1, 200, { from: accounts[3] });
    await unitFarmManager.deposit(1, 300, { from: accounts[4] });
    
    const burnManagerBalance = await wGOLDToken.balanceOf(burnManager.address);
    expect(burnManagerBalance.toString()).to.be.equal('0');
    await burnManager.burn(wGOLDToken.address);

    const totalSupplyAfterBurn = await wGOLDToken.totalSupply();
    expect(totalSupplyAfterBurn.toString()).to.be.equal('10000000');

    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('400');
    expect((await wGOLDToken.balanceOf(accounts[3])).toString()).to.be.equal('1200');
    expect((await wGOLDToken.balanceOf(accounts[4])).toString()).to.be.equal('2000');

    await unitFarmManager.deposit(0, '100', { from: accounts[2] });
    await unitFarmManager.deposit(0, '200', { from: accounts[3] });
    await unitFarmManager.deposit(0, '300', { from: accounts[4] });

    const account2Amount = await unitFarmManager.getUserAmount(0, accounts[2]);
    const account3Amount = await unitFarmManager.getUserAmount(0, accounts[3]);
    const account4Amount = await unitFarmManager.getUserAmount(0, accounts[4]);

    expect(account2Amount.toString()).to.be.equal('600');
    expect(account3Amount.toString()).to.be.equal('800');
    expect(account4Amount.toString()).to.be.equal('1000');

    let wARCHERPool = await unitFarmManager.poolInfo(0);
    let wWARRIORPool = await unitFarmManager.poolInfo(1);

    expect(wARCHERPool.balance.toString()).to.be.equal('2400');
    expect(wWARRIORPool.balance.toString()).to.be.equal('600');

    const pendingwARCHERAccount1 = await unitFarmManager.pendingTokens(0, accounts[1]);
    const pendingwARCHERAccount2 = await unitFarmManager.pendingTokens(0, accounts[2]);
    const pendingwARCHERAccount3 = await unitFarmManager.pendingTokens(0, accounts[3]);

    const pendingwWARRIORAccount1 = await unitFarmManager.pendingTokens(1, accounts[1]);
    const pendingwWARRIORAccount2 = await unitFarmManager.pendingTokens(1, accounts[2]);
    const pendingwWARRIORAccount3 = await unitFarmManager.pendingTokens(1, accounts[3]);

    console.log({
      pendingwARCHERAccount1: pendingwARCHERAccount1.toString(),
      pendingwARCHERAccount2: pendingwARCHERAccount2.toString(),
      pendingwARCHERAccount3: pendingwARCHERAccount3.toString(),
      pendingwWARRIORAccount1: pendingwWARRIORAccount1.toString(),
      pendingwWARRIORAccount2: pendingwWARRIORAccount2.toString(),
      pendingwWARRIORAccount3: pendingwWARRIORAccount3.toString(),
    })

    try {
      await unitFarmManager.withdraw(0, '700', { from: accounts[2] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('withdraw: not good');
    }

    await unitFarmManager.withdraw(0, '600', { from: accounts[2] });
    await unitFarmManager.withdraw(1, '100', { from: accounts[2] });

    await unitFarmManager.withdraw(0, '800', { from: accounts[3] });
    await unitFarmManager.withdraw(0, '1000', { from: accounts[4] });

    wARCHERPool = await unitFarmManager.poolInfo(0);
    wWARRIORPool = await unitFarmManager.poolInfo(1);

    expect(wARCHERPool.balance.toString()).to.be.equal('0');
    expect(wWARRIORPool.balance.toString()).to.be.equal('500');

    await unitFarmManager.set(
      0,
      1000,
      burnManager.address,
      web3.utils.toWei('1', 'ether'),
      true
    );
  });
});

contract('UnitFarmManager > Checking pending tokens', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let wGOLDToken = null;
  let unitFarmManager = null;
  let burnManager = null;
  let wWARRIOR = null;

  it('should setup tokens and farm', async () => {
    const currentBlock = await web3.eth.getBlockNumber();
    wGOLDToken = await APWarsGoldToken.new('wGOLD', 'wGOLD');
    wARCHER = await APWarsBaseToken.new('wARCHER', 'wARCHER');
    wWARRIOR = await APWarsBaseToken.new('wWARRIOR', 'wWARRIOR');
    burnManager = await APWarsBurnManagerMOCK.new();
    unitFarmManager = await APWarsUnitFarmManager.new(accounts[0], currentBlock);

    await Promise.all(
      [
        wGOLDToken,
      ].map(token => token.mint(accounts[0], UNIT_DEFAULT_SUPPLY))
    );

    await wGOLDToken.transfer(accounts[2], 1000);
    await wGOLDToken.transfer(accounts[3], 1000);
    await wGOLDToken.approve(unitFarmManager.address, 1000, { from: accounts[2] });
    await wGOLDToken.approve(unitFarmManager.address, 1000, { from: accounts[3] });
    await wARCHER.transferOwnership(unitFarmManager.address);
    await wWARRIOR.transferOwnership(unitFarmManager.address);

    await unitFarmManager.add(wARCHER.address,
      10,
      1000,
      wGOLDToken.address,
      burnManager.address,
      true
    );
    await unitFarmManager.add(wWARRIOR.address,
      20,
      10000,
      wGOLDToken.address,
      burnManager.address,
      true
    );

    await unitFarmManager.deposit(0, 500, { from: accounts[2] });
    await unitFarmManager.deposit(1, 400, { from: accounts[3] });
    const account2AmountPool1 = await unitFarmManager.getUserAmount(0, accounts[2]);
    const account3AmountPool1 = await unitFarmManager.getUserAmount(0, accounts[3]);
    const account2AmountPool2 = await unitFarmManager.getUserAmount(1, accounts[2]);
    const account3AmountPool2 = await unitFarmManager.getUserAmount(1, accounts[3]);
    expect(account2AmountPool1.toString()).to.be.equal('500');
    expect(account3AmountPool1.toString()).to.be.equal('0');
    expect(account2AmountPool2.toString()).to.be.equal('0');
    expect(account3AmountPool2.toString()).to.be.equal('400');

    let wARCHERPool = await unitFarmManager.poolInfo(0);
    let wWARRIORPool = await unitFarmManager.poolInfo(1);
    expect(wARCHERPool.balance.toString()).to.be.equal('500');
    expect(wWARRIORPool.balance.toString()).to.be.equal('400');

    // moving 5 block (+1 from second deposit)
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);

    let pendingwARCHERAccount2 = await unitFarmManager.pendingTokens(0, accounts[2]);
    let pendingwARCHERAccount3 = await unitFarmManager.pendingTokens(0, accounts[3]);
    let pendingwWARRIORAccount2 = await unitFarmManager.pendingTokens(1, accounts[2]);
    let pendingwWARRIORccount3 = await unitFarmManager.pendingTokens(1, accounts[3]);
    expect(pendingwARCHERAccount2.toString()).to.be.equal('60');
    expect(pendingwARCHERAccount3.toString()).to.be.equal('0');
    expect(pendingwWARRIORAccount2.toString()).to.be.equal('0');
    expect(pendingwWARRIORccount3.toString()).to.be.equal('100');

    await unitFarmManager.deposit(0, 500, { from: accounts[3] });
    await unitFarmManager.deposit(1, 400, { from: accounts[2] });

    // moving 1 block
    await wGOLDToken.transfer(accounts[3], 1);

    pendingwARCHERAccount2 = await unitFarmManager.pendingTokens(0, accounts[2]);
    pendingwARCHERAccount3 = await unitFarmManager.pendingTokens(0, accounts[3]);
    pendingwWARRIORAccount2 = await unitFarmManager.pendingTokens(1, accounts[2]);
    pendingwWARRIORccount3 = await unitFarmManager.pendingTokens(1, accounts[3]);
    expect(pendingwARCHERAccount2.toString()).to.be.equal('80');
    expect(pendingwARCHERAccount3.toString()).to.be.equal('10');
    expect(pendingwWARRIORAccount2.toString()).to.be.equal('10');
    expect(pendingwWARRIORccount3.toString()).to.be.equal('150');
    

    expect((await wARCHER.balanceOf(accounts[2])).toString()).to.be.equal('0'); 
    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('100'); 
    await unitFarmManager.withdraw(0, '500', { from: accounts[2] });

    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('600');
    expect((await wARCHER.balanceOf(accounts[2])).toString()).to.be.equal('85'); //+5 due to withdraw request
  });
});

contract('UnitFarmManager > Checking pending tokens (same user but different pools)', accounts => {
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let wGOLDToken = null;
  let unitFarmManager = null;
  let burnManager = null;
  let wWARRIOR = null;

  it('should setup tokens and farm', async () => {
    const currentBlock = await web3.eth.getBlockNumber();
    wGOLDToken = await APWarsGoldToken.new('wGOLD', 'wGOLD');
    wARCHER = await APWarsBaseToken.new('wARCHER', 'wARCHER');
    wWARRIOR = await APWarsBaseToken.new('wWARRIOR', 'wWARRIOR');
    burnManager = await APWarsBurnManagerMOCK.new();
    unitFarmManager = await APWarsUnitFarmManager.new(accounts[0], currentBlock);

    await Promise.all(
      [
        wGOLDToken,
      ].map(token => token.mint(accounts[0], UNIT_DEFAULT_SUPPLY))
    );

    await wGOLDToken.transfer(accounts[2], 1000);
    await wGOLDToken.approve(unitFarmManager.address, 1000, { from: accounts[2] });
    await wARCHER.transferOwnership(unitFarmManager.address);
    await wWARRIOR.transferOwnership(unitFarmManager.address);

    await unitFarmManager.add(wARCHER.address,
      10,
      1000,
      wGOLDToken.address,
      burnManager.address,
      true
    );
    await unitFarmManager.add(wWARRIOR.address,
      20,
      10000,
      wGOLDToken.address,
      burnManager.address,
      true
    );

    await unitFarmManager.deposit(0, 200, { from: accounts[2] });
    await unitFarmManager.deposit(1, 400, { from: accounts[2] });
    const account2AmountPool1 = await unitFarmManager.getUserAmount(0, accounts[2]);
    const account2AmountPool2 = await unitFarmManager.getUserAmount(1, accounts[2]);
    expect(account2AmountPool1.toString()).to.be.equal('200');
    expect(account2AmountPool2.toString()).to.be.equal('400');

    let wARCHERPool = await unitFarmManager.poolInfo(0);
    let wWARRIORPool = await unitFarmManager.poolInfo(1);
    expect(wARCHERPool.balance.toString()).to.be.equal('200');
    expect(wWARRIORPool.balance.toString()).to.be.equal('400');

    // moving 5 block (+1 from second deposit)
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);
    await wGOLDToken.transfer(accounts[3], 1);

    let pendingwARCHERAccount2 = await unitFarmManager.pendingTokens(0, accounts[2]);
    let pendingwWARRIORAccount2 = await unitFarmManager.pendingTokens(1, accounts[2]);
    expect(pendingwARCHERAccount2.toString()).to.be.equal('60');
    expect(pendingwWARRIORAccount2.toString()).to.be.equal('100');

    expect((await wARCHER.balanceOf(accounts[2])).toString()).to.be.equal('0'); 
    expect((await wWARRIOR.balanceOf(accounts[2])).toString()).to.be.equal('0'); 
    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('400'); 
    await unitFarmManager.withdraw(0, '200', { from: accounts[2] });
    await unitFarmManager.withdraw(1, '400', { from: accounts[2] });

    expect((await wGOLDToken.balanceOf(accounts[2])).toString()).to.be.equal('1000');
    expect((await wARCHER.balanceOf(accounts[2])).toString()).to.be.equal('70'); //+20 due to withdraw request
    expect((await wWARRIOR.balanceOf(accounts[2])).toString()).to.be.equal('140'); //+20 due to withdraw request
  });
});