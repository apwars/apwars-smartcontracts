const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsMarketNFTSwapEscrow = artifacts.require('APWarsMarketNFTSwapEscrow');

var sleep = require('sleep');

contract.only('APWarsMarketNFTSwapEscrow', accounts => {
  let burnManager = null;
  let wGOLD = null;
  let collectibles = null;
  let escrow = null;

  it('should deploy the contracts', async () => {
    burnManager = await APWarsBurnManager.new(accounts[2]);
    wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');

    await wGOLD.mint(accounts[0], web3.utils.toWei('100', 'ether'));
    await wGOLD.mint(accounts[2], web3.utils.toWei('100', 'ether'));

    await collectibles.mint(accounts[1], 7, 6, '0x0');
    await collectibles.mint(accounts[2], 10, 1, '0x0');
    await collectibles.mint(accounts[3], 11, 1, '0x0');

    escrow = await APWarsMarketNFTSwapEscrow.new();
  });

  it('should setup system', async () => {
    await escrow.setup(accounts[9], 250, [wGOLD.address]);

    expect(await escrow.getFeeAddress()).to.be.equal(accounts[9]);
    expect((await escrow.getSwapFeeRate()).toString()).to.be.equal('250');

    const allowedTokens = await escrow.getAllowedTokens();

    expect(allowedTokens.length).to.be.equal(1);
    expect(allowedTokens[0]).to.be.equal(wGOLD.address);
  });

  it('should create a sell order and execute it', async () => {
    try {
      await escrow.createOrder(1, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), 1, {from: accounts[1]});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('ERC1155: caller is not owner nor approved');
    }

    await collectibles.setApprovalForAll(escrow.address, true, {from: accounts[1]});
    const gas = await escrow.createOrder.estimateGas(1, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), 3, { from: accounts[1] });
    await escrow.createOrder(1, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), 3, { from: accounts[1] });
    
    console.log({ gas });

    let orderInfo = await escrow.getOrderInfo(0);

    expect(orderInfo.sender).to.be.equal(accounts[1], 'fail to check seller');
    expect(orderInfo.orderType.toString()).to.be.equal('1', 'fail to check orderType');
    expect(orderInfo.orderStatus.toString()).to.be.equal('0', 'fail to check orderStatus');
    expect(orderInfo.tokenAddress).to.be.equal(collectibles.address, 'fail to check tokenAddress');
    expect(orderInfo.tokenId.toString()).to.be.equal('7', 'fail to check tokenId');
    expect(orderInfo.tokenPriceAddress).to.be.equal(wGOLD.address, 'fail to check tokenPriceAddress');
    expect(orderInfo.amount.toString()).to.be.equal(web3.utils.toWei('10', 'ether'), 'fail to check amount');
    expect(orderInfo.quantity.toString()).to.be.equal('3', 'fail to check quantity');
    expect(orderInfo.feeAmount.toString()).to.be.equal(web3.utils.toWei('0.25', 'ether'), 'fail to check feeAmount');
    expect(orderInfo.totalAmount.toString()).to.be.equal(web3.utils.toWei('10.25', 'ether'), 'fail to check totalAmount');

    expect((await escrow.getSellOrdersLength()).toString()).to.be.equal('1', 'fail to check getSellOrdersLength');
    expect((await escrow.getBuyOrdersLength()).toString()).to.be.equal('0', 'fail to check getBuyOrdersLength');

    await wGOLD.approve(escrow.address, await wGOLD.balanceOf(accounts[2]), {from: accounts[2]});
    await escrow.executeOrder(0, 1, { from: accounts[2] });

    orderInfo = await escrow.getOrderInfo(0);
    expect(orderInfo.quantity.toString()).to.be.equal('2', 'fail to check quantity #2');
    expect(orderInfo.orderStatus.toString()).to.be.equal('0', 'fail to check orderStatus #2');

    await escrow.executeOrder(0, 2, { from: accounts[2] });

    orderInfo = await escrow.getOrderInfo(0);
    expect(orderInfo.quantity.toString()).to.be.equal('0', 'fail to check quantity #3');
    expect(orderInfo.orderStatus.toString()).to.be.equal('2', 'fail to check orderStatus #3');
  });

  it('should create a buy order', async () => {
    const gas = await escrow.createOrder.estimateGas(0, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), 3, { from: accounts[2] });
    await escrow.createOrder(0, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), 3, { from: accounts[2] });
    
    console.log({ gas });

    let orderInfo = await escrow.getOrderInfo(1);

    expect(orderInfo.sender).to.be.equal(accounts[2], 'fail to check buyer');
    expect(orderInfo.orderType.toString()).to.be.equal('0', 'fail to check orderType');
    expect(orderInfo.orderStatus.toString()).to.be.equal('0', 'fail to check orderStatus');
    expect(orderInfo.tokenAddress).to.be.equal(collectibles.address, 'fail to check tokenAddress');
    expect(orderInfo.tokenId.toString()).to.be.equal('7', 'fail to check tokenId');
    expect(orderInfo.tokenPriceAddress).to.be.equal(wGOLD.address, 'fail to check tokenPriceAddress');
    expect(orderInfo.amount.toString()).to.be.equal(web3.utils.toWei('10', 'ether'), 'fail to check amount');
    expect(orderInfo.quantity.toString()).to.be.equal('3', 'fail to check quantity');
    expect(orderInfo.feeAmount.toString()).to.be.equal(web3.utils.toWei('0.25', 'ether'), 'fail to check feeAmount');
    expect(orderInfo.totalAmount.toString()).to.be.equal(web3.utils.toWei('10.25', 'ether'), 'fail to check totalAmount');

    expect((await escrow.getSellOrdersLength()).toString()).to.be.equal('1', 'fail to check getSellOrdersLength');
    expect((await escrow.getBuyOrdersLength()).toString()).to.be.equal('1', 'fail to check getBuyOrdersLength');

    await escrow.executeOrder(1, 2, { from: accounts[1] });

    orderInfo = await escrow.getOrderInfo(1);
    expect(orderInfo.orderStatus.toString()).to.be.equal('0', 'fail to check orderStatus #2');
    expect(orderInfo.quantity.toString()).to.be.equal('1', 'fail to check quantity #2');

    await escrow.cancelOrder(1, { from: accounts[2] });

    orderInfo = await escrow.getOrderInfo(1);
    expect(orderInfo.orderStatus.toString()).to.be.equal('1', 'fail to check orderStatus #3');
  });
});
