const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsMarketNFTSwapEscrow = artifacts.require('APWarsMarketNFTSwapEscrow');

var sleep = require('sleep');

contract('APWarsMarketNFTSwapEscrow', accounts => {
  let burnManager = null;
  let wGOLD = null;
  let collectibles = null;
  let escrow = null;

  it.only('should deploy the contracts', async () => {
    burnManager = await APWarsBurnManager.new(accounts[2]);
    wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');

    await wGOLD.mint(accounts[0], web3.utils.toWei('100', 'ether'));

    await collectibles.mint(accounts[1], 7, 1, '0x0');
    await collectibles.mint(accounts[2], 10, 1, '0x0');
    await collectibles.mint(accounts[3], 11, 1, '0x0');

    escrow = await APWarsMarketNFTSwapEscrow.new();
  });

  it.only('should setup system', async () => {
    await escrow.setup(accounts[9], 250, [wGOLD.address]);

    expect(await escrow.getFeeAddress()).to.be.equal(accounts[9]);
    expect((await escrow.getSwapFeeRate()).toString()).to.be.equal('250');

    const allowedTokens = await escrow.getAllowedTokens();

    expect(allowedTokens.length).to.be.equal(1);
    expect(allowedTokens[0]).to.be.equal(wGOLD.address);
  });

  it.only('should create a sell order', async () => {
    try {
      await escrow.createOrder(1, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), {from: accounts[1]});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsMarketNFTSwapEscrow:ERC1155_NOT_APPROVED');
    }

    await collectibles.setApprovalForAll(escrow.address, true, {from: accounts[1]});
    await escrow.createOrder(1, collectibles.address, 7, wGOLD.address, web3.utils.toWei('10', 'ether'), {from: accounts[1]});

    console.log(accounts[1], collectibles.address, 0);
    
    const ordersId = await escrow.getOrderIds(accounts[1], collectibles.address, 0);

    console.log({ ordersId });

    const orderInfo = await escrow.getOrderInfo(ordersId[0], 1);

    expect(orderInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');

    expect((await escrow.getSellOrdersLength()).toString()).to.be.equal('0', 'fail to check getSellOrdersLength');
    expect((await escrow.getBuyOrdersLength()).toString()).to.be.equal('1', 'fail to check getBuyOrdersLength');


    console.log({ orderInfo });
  });
});
