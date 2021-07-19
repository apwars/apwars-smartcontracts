const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsCombinator = artifacts.require('APWarsCombinator');

var sleep = require('sleep');

contract('APWarsCombinator', accounts => {
  let burnManager = null;
  let wGOLD = null;
  let wWARRIOR = null;
  let collectibles = null;
  let combinator = null;

  it('should deploy the contracts', async () => {
    burnManager = await APWarsBurnManager.new(accounts[2]);
    wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    wWARRIOR = await APWarsBaseToken.new('wWARRIOR', 'wWARRIOR');
    collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');
    combinator = await APWarsCombinator.new();

    await wGOLD.mint(accounts[0], web3.utils.toWei('1000000000', 'ether'));
    await wWARRIOR.mint(accounts[0], web3.utils.toWei('100000000', 'ether'));

    await collectibles.mint(combinator.address, 10, 100, '0x0');
  });

  it('should setup a combinator', async () => {
    await combinator.setupCombinator(1, 3, 2, true);
    await combinator.setupTokens(
      1,
      wGOLD.address,
      web3.utils.toWei('100', 'ether'),
      0,
      0,
      wWARRIOR.address,
      web3.utils.toWei('1000', 'ether'),
      0,
      0
    );
    await combinator.setupGameItem(
      1,
      collectibles.address,
      10,
      1
    );
  });

  it('should put a combinator on the schedule and fail to claim', async () => {
    await wGOLD.approve(combinator.address, await wGOLD.balanceOf(accounts[0]));
    await wWARRIOR.approve(combinator.address, await wWARRIOR.balanceOf(accounts[0]));

    await combinator.combine(1, 2);

    try {
      await combinator.claim(accounts[0], 1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinator:INVALID_BLOCK");
    }

    //moving 2 blocks forward
    await wGOLD.approve(combinator.address, await wGOLD.balanceOf(accounts[0]));
    await wGOLD.approve(combinator.address, await wGOLD.balanceOf(accounts[0]));

    await combinator.claim(accounts[0], 1);
  });
});
