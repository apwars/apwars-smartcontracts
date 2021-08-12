const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsWisdowToken = artifacts.require('APWarsWisdowToken');
const APWarsLandPrivateSale = artifacts.require('APWarsLandPrivateSale');
const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');

var sleep = require('sleep');

let burnManager = null;
let wLAND = null;
let wWISDOW = null;
let busd = null;
let privateSale = null;
let blockNumber;
let collectibles = null;

const deployContracts = async (accounts, priorityEndBlock, internal, cliff, privateSale) => {
  burnManager = await APWarsBurnManager.new(accounts[2]);
  collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');
  blockNumber = await web3.eth.getBlockNumber();

  wLAND = await APWarsLandToken.new('wLAND', 'wLAND');
  wWISDOW = await APWarsWisdowToken.new('wWISDOW', 'wWISDOW');
  busd = await APWarsBaseToken.new('BUSD', 'BUSD');
  privateSale = await APWarsLandPrivateSale.new(
    wLAND.address,
    wWISDOW.address,
    busd.address,
    collectibles.address,
    10,
    11,
    accounts[3],
    blockNumber + (cliff || 60),
    blockNumber + (privateSale || 30),
    internal || 5,
    blockNumber + (priorityEndBlock || 0),
  );

  await busd.mint(accounts[1], web3.utils.toWei('1000000', 'ether'));
  await busd.mint(accounts[2], web3.utils.toWei('1000000', 'ether'));
  await wLAND.transfer(privateSale.address, web3.utils.toWei('1500000', 'ether'));

  await collectibles.mint(privateSale.address, 10, 2, '0x0');
  await collectibles.mint(privateSale.address, 11, 50, '0x0');

  await privateSale.setupWhitelist([accounts[1], accounts[2]], [web3.utils.toWei('15000', 'ether'), 0], true);

  await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
  await busd.approve(privateSale.address, await busd.balanceOf(accounts[2]), { from: accounts[2] });

  await wWISDOW.grantRole(await wWISDOW.MINTER_ROLE(), privateSale.address);

  console.log('wLAND', wLAND.address);
  console.log('busd', busd.address);
  console.log('privateSale', privateSale.address);
}

contract('APWarswLANDPrivateSale deployment', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts, 20, 50, 200, 100);
  });
});

contract('APWarswLANDPrivateSale deployment', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts, 0);
  });

  it('should test limits', async () => {
    let r = await privateSale.getAvailableAmounts(web3.utils.toWei('0', 'ether'));

    console.log(web3.utils.fromWei(r[0]));
    console.log(web3.utils.fromWei(r[1]));
    console.log(web3.utils.fromWei(r[2]));

    r = await privateSale.getAvailableAmounts(web3.utils.toWei('568000', 'ether'));

    console.log(web3.utils.fromWei(r[0]));
    console.log(web3.utils.fromWei(r[1]));
    console.log(web3.utils.fromWei(r[2]));


    r = await privateSale.getAvailableAmounts(web3.utils.toWei('1329000', 'ether'));

    console.log(web3.utils.fromWei(r[0]));
    console.log(web3.utils.fromWei(r[1]));
    console.log(web3.utils.fromWei(r[2]));


    r = await privateSale.getAmountsByPackage(web3.utils.toWei('0', 'ether'), web3.utils.toWei('1000', 'ether'));

    console.log(web3.utils.fromWei(r[0]));
    console.log(web3.utils.fromWei(r[1]));
    console.log(web3.utils.fromWei(r[2]));


    r = web3.utils.fromWei(await privateSale.getBUSDwLANDPriceAmount(web3.utils.toWei('0', 'ether'), web3.utils.toWei('1000', 'ether')));
    expect(r).to.be.equal('500');

    r = web3.utils.fromWei(await privateSale.getBUSDwLANDPriceAmount(web3.utils.toWei('500000', 'ether'), web3.utils.toWei('1000', 'ether')));
    expect(r).to.be.equal('750');
  });
});

contract('APWarswLANDPrivateSale', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should buy clan ticket', async () => {
    expect((await collectibles.balanceOf(privateSale.address, 11)).toString()).to.be.equal('50', 'fail to check collectibles balance #1');
    await privateSale.buyClanTicket({ from: accounts[1] });
    expect((await collectibles.balanceOf(privateSale.address, 11)).toString()).to.be.equal('50', 'fail to check collectibles balance #2');
    expect((await collectibles.balanceOf(accounts[1], 11)).toString()).to.be.equal('0', 'fail to check collectibles balance #3');
  });

  it('should buy world ticket', async () => {
    expect((await collectibles.balanceOf(privateSale.address, 10)).toString()).to.be.equal('2', 'fail to check collectibles balance #1');
    await privateSale.buyWorldTicket({ from: accounts[1] });
    expect((await collectibles.balanceOf(privateSale.address, 10)).toString()).to.be.equal('2', 'fail to check collectibles balance #2');
    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal('0', 'fail to check collectibles balance #3');
  });

  it('should buy wLAND', async () => {
    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('1000', 'ether'), { from: accounts[2] });

    //clan ticket + world ticket + wLAND
    expect((await busd.balanceOf(accounts[3])).toString()).to.be.equal(web3.utils.toWei((3999 + 39999 + 1900 * 0.5).toString(), 'ether'), "fail to test accounts[0] busd balance");
    
    let info = await privateSale.shares(accounts[1]);

    expect(info.investedAmount.toString()).to.be.equal(web3.utils.toWei('450', 'ether'));
    expect(info.wLANDAmount.toString()).to.be.equal(web3.utils.toWei('900', 'ether'));
    expect(info.remainingAmount.toString()).to.be.equal(web3.utils.toWei('900', 'ether'));
    expect(info.claimedAmount.toString()).to.be.equal(web3.utils.toWei('0', 'ether'));
    expect(info.claims.toString()).to.be.equal('0');
    expect(info.nextBlock.toString()).to.be.equal((blockNumber + 60).toString(), 'ether');
    expect(info.added).to.be.equal(true);

    let currentBlockNumber = await web3.eth.getBlockNumber();
    let nextBlock = parseInt(info.nextBlock.toString());

    console.log({
      currentBlockNumber,
      nextBlock
    })

    try {
      await privateSale.claimwLAND({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:INVALID_BLOCK", "fail to test INVALID_BLOCK");
    }

    for (var i = 0; i < nextBlock - currentBlockNumber; i++) {
      await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    }

    expect((await wLAND.balanceOf(accounts[1])).toString()).to.be.equal('0', "fail to test accounts[1] wLAND balance");

    for (i = 1; i <= 9; i++) {
      console.log({ i });
      await privateSale.claimwLAND({ from: accounts[1] });
      info = await privateSale.shares(accounts[1]);

      expect(info.remainingAmount.toString()).to.be.equal(web3.utils.toWei((900 - (i * 100)).toString(), 'ether'));
      expect(info.claimedAmount.toString()).to.be.equal(web3.utils.toWei((i * 100).toString(), 'ether'));
      expect(info.claims.toString()).to.be.equal(i.toString());
      expect((await wLAND.balanceOf(accounts[1])).toString()).to.be.equal(web3.utils.toWei((i * 100).toString(), 'ether'));
      expect((await wLAND.balanceOf(privateSale.address)).toString()).to.be.equal(web3.utils.toWei((1500000 - i * 100).toString(), 'ether'));

      currentBlockNumber = await web3.eth.getBlockNumber();
      nextBlock = parseInt(info.nextBlock.toString());

      if (info.remainingAmount.toString() !== '0') {
        for (var j = 0; j < nextBlock - currentBlockNumber - 1; j++) {
          try {
            await privateSale.claimwLAND({ from: accounts[1] });
            throw {};
          } catch (e) {
            expect(e.reason).to.be.equal("APWarsLandPrivateSale:INVALID_BLOCK", "fail to test INVALID_BLOCK #" + j);
          }
        }
      }
    }
  });

  it('should claim clan ticket', async () => {
    await privateSale.claimClanTicket({ from: accounts[1] });
    expect((await collectibles.balanceOf(privateSale.address, 11)).toString()).to.be.equal('49', 'fail to check collectibles balance #2');
    expect((await collectibles.balanceOf(accounts[1], 11)).toString()).to.be.equal('1', 'fail to check collectibles balance #3');
  });

  it('should claiim world ticket', async () => {
    await privateSale.claimWorldTicket({ from: accounts[1] });
    expect((await collectibles.balanceOf(privateSale.address, 10)).toString()).to.be.equal('1', 'fail to check collectibles balance #2');
    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal('1', 'fail to check collectibles balance #3');
  });
});

contract('APWarswLANDPrivateSale wWISDOW', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should buy less than soft cap and fail to claim', async () => {
    await privateSale.buywLAND(web3.utils.toWei('100000', 'ether'), { from: accounts[1] });
    
    let info = await privateSale.shares(accounts[1]);

    expect(info.wWISDOWToClaim.toString()).to.be.equal(web3.utils.toWei('10', 'ether'));

    try {
      await privateSale.claimwWISDOW({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:OPENED_SOFT_CAP", "fail to test OPENED_SOFT_CAP");
    }
    await privateSale.buywLAND(web3.utils.toWei('300000', 'ether'), { from: accounts[1] });
    await privateSale.claimwWISDOW({ from: accounts[1] });

    const result = await privateSale.investedAmount();
    console.log({ result: result.toString() });

    expect((await wWISDOW.balanceOf(accounts[1])).toString()).to.be.equal(web3.utils.toWei('40', 'ether'));

    try {
      await privateSale.claimwWISDOW({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:NOTHING_TO_CLAIM", "fail to test NOTHING_TO_CLAIM");
    }
  });
});

contract('APWarswLANDPrivateSale priority lock', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts, 20);
  });

  it('should buy only the specified amount in priority lock and wait to buy more', async () => {
    try {
      await privateSale.buywLAND(web3.utils.toWei('100', 'ether'), { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:PRIORITY_LEVEL", "fail to test PRIORITY_LEVEL");
    }

    await privateSale.buywLAND(web3.utils.toWei('15000', 'ether'), { from: accounts[1] });

    //trying to buy again and get the error
    try {
      await privateSale.buywLAND(web3.utils.toWei('15000', 'ether'), { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:PRIORITY_LEVEL", "fail to test PRIORITY_LEVEL");
    }

    let currentBlockNumber = await web3.eth.getBlockNumber();
    let nextBlock = parseInt((await privateSale.priorityEndBlock()).toString());

    console.log({
      currentBlockNumber,
      nextBlock
    });

    for (var i = 0; i < nextBlock - currentBlockNumber; i++) {
      await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    }

    await privateSale.buywLAND(web3.utils.toWei('15000', 'ether'), { from: accounts[1] });
  });
});

contract('APWarswLANDPrivateSale withdrawing remaining tokens', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts, 20);
  });

  it('should withdraw the remaining amount', async () => {
    let currentBlockNumber = await web3.eth.getBlockNumber();
    let nextBlock = parseInt((await privateSale.priorityEndBlock()).toString());

    console.log({
      currentBlockNumber,
      nextBlock
    });

    for (var i = 0; i < nextBlock - currentBlockNumber; i++) {
      await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    }

    await privateSale.buywLAND(web3.utils.toWei('1000000', 'ether'), { from: accounts[1] });

    currentBlockNumber = await web3.eth.getBlockNumber();
    nextBlock = parseInt((await privateSale.privateSaleEndBlock()).toString());
    wLANDSoldAmount = parseInt((await privateSale.wLANDSoldAmount()).toString());

    console.log({
      currentBlockNumber,
      nextBlock,
      wLANDSoldAmount
    });

    for (var i = 0; i < nextBlock - currentBlockNumber; i++) {
      await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    }

    await privateSale.withdrawRemainingwLand();

    expect((await wLAND.balanceOf(accounts[0])).toString()).to.be.equal(web3.utils.toWei('500000', 'ether'));
  });
});

contract('APWarswLANDPrivateSale exceptions', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts, 20);
  });

  it('should fail to buy more than available supply', async () => {
    let currentBlockNumber = await web3.eth.getBlockNumber();
    let nextBlock = parseInt((await privateSale.priorityEndBlock()).toString());

    for (var i = 0; i < nextBlock - currentBlockNumber; i++) {
      await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    }

    try {
      await privateSale.buywLAND(web3.utils.toWei('1500000', 'ether'), { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsLandPrivateSale:MAX_AVAILABLE_SUPPLY", "fail to test APWarsLandPrivateSale:MAX_AVAILABLE_SUPPLY");
    }
  });
});