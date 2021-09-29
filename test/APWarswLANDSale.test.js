const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsLandSale = artifacts.require('APWarsLandSale');
const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');

var sleep = require('sleep');

let burnManager = null;
let wLAND = null;
let busd = null;
let landSale = null;
let collectibles = null;
const ref = web3.utils.keccak256("TEST");

const deployContracts = async (accounts) => {
  burnManager = await APWarsBurnManager.new(accounts[2]);
  collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');

  wLAND = await APWarsLandToken.new('wLAND', 'wLAND');
  busd = await APWarsBaseToken.new('BUSD', 'BUSD');
  _idTickets = [58, 59, 60, 61, 62];
  _priceTickets = [
    web3.utils.toWei('1500', 'ether'),
    web3.utils.toWei('1000', 'ether'),
    web3.utils.toWei('1000', 'ether'),
    web3.utils.toWei('500', 'ether'),
    web3.utils.toWei('500', 'ether'),
  ];

  landSale = await APWarsLandSale.new(
    wLAND.address,
    busd.address,
    collectibles.address,
    accounts[8],
    _idTickets,
    _priceTickets
  );

  await busd.mint(accounts[1], web3.utils.toWei('2500000', 'ether'));
  await busd.mint(accounts[2], web3.utils.toWei('2500000', 'ether'));
  await wLAND.transfer(landSale.address, web3.utils.toWei('1500000', 'ether'));

  for (id in _idTickets) {
    await collectibles.mint(landSale.address, _idTickets[id], 100, '0x0');
  }

  await busd.approve(landSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
  await busd.approve(landSale.address, await busd.balanceOf(accounts[2]), { from: accounts[2] });

  await wLAND.approve(landSale.address, web3.utils.toWei('1500000', 'ether'), { from: accounts[1] });
  await wLAND.approve(landSale.address, web3.utils.toWei('1500000', 'ether'), { from: accounts[2] });


  console.log('wLAND', wLAND.address);
  console.log('busd', busd.address);
  console.log('landSale', landSale.address);
}

contract.only('APWarswLANDlandSale buy wLAND', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should test amount 0', async () => {

    try {
      await landSale.buywLAND(0, ref);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsLandSale:INVALID_AMOUNT", "fail to test INVALID_AMOUNT");
    }

  });

  it('should test fail to pay', async () => {
    try {
      await landSale.buywLAND(10, ref, { from: accounts[3] });
    } catch (error) {
      expect(error.reason).to.be.equal("BEP20: transfer amount exceeds balance");
    }
  });

  it('should test buy wLAND', async () => {

    let balanceBUSD = await busd.balanceOf(accounts[1], { from: accounts[1] });

    const amountBuy = 10;
    await landSale.buywLAND(amountBuy, ref, { from: accounts[1] });

    const reduceBalance = web3.utils.fromWei(balanceBUSD) - (amountBuy * 1.5);
    const newBalance = web3.utils.fromWei(await busd.balanceOf(accounts[1], { from: accounts[1] }));

    expect(reduceBalance).to.be.equal(parseFloat(newBalance));

    let balancewLAND = await wLAND.balanceOf(accounts[1], { from: accounts[1] });
    expect(balancewLAND.toString()).to.be.equal(web3.utils.toWei(amountBuy.toString(), 'ether'));

  });

  it('should test buy wLAND more than the total available', async () => {
    try {
      const amountBuy = 1500000;
      await landSale.buywLAND(amountBuy, ref, { from: accounts[2] });

    } catch (error) {
      expect(error.reason).to.be.equal("APWarsLandSale:INVALID_BALANCE");
    }
  });

  it('should test buy wLAND after already having purchased', async () => {

    let balanceBUSD = await busd.balanceOf(accounts[1], { from: accounts[1] });

    const amountBuy = 13246;
    await landSale.buywLAND(amountBuy, ref, { from: accounts[1] });

    const reduceBalance = web3.utils.fromWei(balanceBUSD) - (amountBuy * 1.5);
    const newBalance = web3.utils.fromWei(await busd.balanceOf(accounts[1], { from: accounts[1] }));

    expect(reduceBalance).to.be.equal(parseFloat(newBalance));

    let lastBuy = 10 + amountBuy;
    let balancewLAND = await wLAND.balanceOf(accounts[1], { from: accounts[1] });
    expect(balancewLAND.toString()).to.be.equal(web3.utils.toWei(lastBuy.toString(), 'ether'));

  });

  it('should test buy ticket not registered', async () => {
    try {
      await landSale.buyTicket(15, 1, ref, { from: accounts[2] });

    } catch (error) {
      expect(error.reason).to.be.equal("APWarsLandSale:TICKET_INVALID_AMOUNT");
    }
  });


  it('should test buy ticket without wLAND', async () => {
    try {
      await landSale.buyTicket(62, 1, ref, { from: accounts[2] });
    } catch (error) {
      expect(error.reason).to.be.equal("ERC20: transfer amount exceeds balance");
    }
  });

  it('should test buy 1 ticket', async () => {

    const idTicket = 62;
    const amount = 1;
    let balancelandSale = await collectibles.balanceOf(landSale.address, idTicket);
    balancelandSale = parseInt(balancelandSale);
    await landSale.buyTicket(idTicket, amount, ref, { from: accounts[1] });

    let balanceAccount1 = await collectibles.balanceOf(accounts[1], idTicket);
    balanceAccount1 = parseInt(balanceAccount1.toString());

    expect(balanceAccount1).to.be.equal(amount);

    let newBalancelandSale = await collectibles.balanceOf(landSale.address, idTicket);
    newBalancelandSale = parseInt(newBalancelandSale.toString());
    expect(balancelandSale - amount).to.be.equal(newBalancelandSale);

  });

  it('should test buying 3 units of all tickets', async () => {

    const amountBuywLAND = 150054;
    await landSale.buywLAND(amountBuywLAND, ref, { from: accounts[2] });

    const amount = 3;

    for (id in _idTickets) {
      await landSale.buyTicket(_idTickets[id], amount, ref, { from: accounts[2] });

      let balanceAccount2 = await collectibles.balanceOf(accounts[2], _idTickets[id]);
      balanceAccount2 = parseInt(balanceAccount2.toString());
      expect(balanceAccount2).to.be.equal(amount);
    }

  });

  it('should test buying all units from ticket 61', async () => {

    const idTicket = 61;
    const amount = await collectibles.balanceOf(landSale.address, idTicket);

    await landSale.buyTicket(idTicket, amount.toString(), ref, { from: accounts[2] });

    const newAmount = await collectibles.balanceOf(landSale.address, idTicket);
    expect(parseInt(newAmount)).to.be.equal(0);

    let balanceAccount2 = await collectibles.balanceOf(accounts[2], idTicket);
    balanceAccount2 = parseInt(balanceAccount2.toString());
    expect(balanceAccount2).to.be.equal(100);

  });

  it('should test buy ticket sold out', async () => {
    const idTicket = 61;
    const amount = 1;
    try {
      await landSale.buyTicket(idTicket, amount, ref, { from: accounts[1] });
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsLandSale:TICKET_SOLD_OUT");
    }

    await landSale.buyTicket(idTicket - 1, amount, ref, { from: accounts[1] });
    let balanceAccount1 = await collectibles.balanceOf(accounts[1], idTicket - 1);
    balanceAccount1 = parseInt(balanceAccount1.toString());
    expect(balanceAccount1).to.be.equal(1);
  });


  it('should test buy all wLAND', async () => {
    const amountBuyWei = await wLAND.balanceOf(landSale.address);
    const amountBuy = web3.utils.fromWei(amountBuyWei);
    await landSale.buywLAND(amountBuy, ref, { from: accounts[1] });
    let amountwLANDlandSale = await wLAND.balanceOf(landSale.address);
    expect(parseInt(amountwLANDlandSale)).to.be.equal(0);
  });

  it('should test buy wLAND invalid amount', async () => {
    const amountBuy = 1;
    try {
      await landSale.buywLAND(amountBuy, ref, { from: accounts[2] });
    } catch(error){
      expect(error.reason).to.be.equal("APWarsLandSale:INVALID_BALANCE");
    }
  });

});

