const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsCombinatorTokenGameItem = artifacts.require('APWarsCombinatorTokenGameItem');
const APWarsCombinatorManager = artifacts.require('APWarsCombinatorManager');
const APWarsCourageToken = artifacts.require('APWarsCourageToken');

var sleep = require('sleep');

let burnManager = null;
let wGOLD = null;
let wWARRIOR = null;
let collectibles = null;
let combinator = null;
let combinatorManager = null;


const deployContracts = async (accounts) => {
  burnManager = await APWarsBurnManager.new(accounts[2]);
  wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
  wWARRIOR = await APWarsBaseToken.new('wWARRIOR', 'wWARRIOR');
  collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');
  combinator = await APWarsCombinatorTokenGameItem.new();
  combinatorManager = await APWarsCombinatorManager.new();
  wCOURAGE = await APWarsCourageToken.new("wCOURAGE", "wCOURAGE");

  await wGOLD.mint(accounts[0], web3.utils.toWei('1000000', 'ether'));
  await wCOURAGE.mint(accounts[0], web3.utils.toWei('1000000', 'ether'));
  await wWARRIOR.mint(accounts[0], web3.utils.toWei('20000000000000', 'ether'));

  await collectibles.mint(accounts[0], 10, 100, '0x0');
  await collectibles.mint(combinator.address, 11, 100, '0x0');

  await combinator.setup(accounts[8], burnManager.address, combinatorManager.address);
  wCOURAGE.grantRole(await wCOURAGE.MINTER_ROLE(), combinator.address);
}

contract('APWarsCombinator > Token A + GameItem B -> Game Item C', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should setup a combinator', async () => {
    await combinatorManager.setupCombinator(1, 3, 2, true);
    await combinatorManager.setupTokenA(
      1,
      wCOURAGE.address,
      web3.utils.toWei('100', 'ether'),
      0,
      10000,
    );

    await combinatorManager.setupGameItemB(
      1,
      collectibles.address,
      10,
      1,
      0,
      0
    );
    await combinatorManager.setupGameItemC(
      1,
      collectibles.address,
      11,
      10,
      0,
      0
    );
  });

  it('should put a combinator on the schedule', async () => {
    await wCOURAGE.approve(combinator.address, await wCOURAGE.balanceOf(accounts[0]));
    await collectibles.setApprovalForAll(combinator.address, accounts[0]);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal('0', 'fail to check wCOURAGE balance #1');

    await combinator.combineTokens(1, 2);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal(web3.utils.toWei('0', 'ether'), 'fail to check wCOURAGE balance');

    try {
      await combinator.claimGameItemFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorTokenGameItem:INVALID_BLOCK");
    }

    //moving 2 blocks forward
    await wCOURAGE.approve(combinator.address, await wCOURAGE.balanceOf(accounts[0]));
    await wCOURAGE.approve(combinator.address, await wCOURAGE.balanceOf(accounts[0]));

    try {
      await combinator.claimTokenFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorManager:INVALID_ID_C");
    }

    await combinator.claimGameItemFromTokens(1);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal('0', 'fail to check wCOURAGE balance #3');

    expect((await wCOURAGE.balanceOf(accounts[8])).toString()).to.be.equal(web3.utils.toWei('200', 'ether'), 'check wCOURAGE fee');

    expect((await collectibles.balanceOf(accounts[8], 11)).toString()).to.be.equal('2', 'fail to check collectibles balance accounts[8] #3');
    expect((await collectibles.balanceOf(accounts[0], 11)).toString()).to.be.equal('20', 'fail to check collectibles balance accounts[0] #3');
    

    try {
      await combinator.claimGameItemFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorTokenGameItem:INVALID_CONFIG");
    }
  });
});


contract('APWarsCombinator > Token A + GameItem B -> Token C', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should setup a combinator', async () => {
    await combinatorManager.setupCombinator(1, 3, 2, true);
    await combinatorManager.setupTokenA(
      1,
      wWARRIOR.address,
      web3.utils.toWei('100', 'ether'),
      0,
      10000,
    );

    await combinatorManager.setupGameItemB(
      1,
      collectibles.address,
      10,
      1,
      0,
      0
    );
    await combinatorManager.setupTokenC(
      1,
      wCOURAGE.address,
      web3.utils.toWei('100', 'ether'),
      0,
      0
    );
  });

  it('should put a combinator on the schedule', async () => {
    await wCOURAGE.approve(combinator.address, await wCOURAGE.balanceOf(accounts[0]));
    await wWARRIOR.approve(combinator.address, await wWARRIOR.balanceOf(accounts[0]));
    await collectibles.setApprovalForAll(combinator.address, accounts[0]);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal('0', 'fail to check wCOURAGE balance #1');
    expect((await wWARRIOR.balanceOf(combinator.address)).toString()).to.be.equal('0', 'fail to check wCOURAGE balance #1');

    await combinator.combineTokens(1, 2);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal(web3.utils.toWei('0', 'ether'), 'fail to check wCOURAGE balance');


    try {
      await combinator.claimTokenFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorTokenGameItem:INVALID_BLOCK");
    }

    //moving 2 blocks forward
    await wCOURAGE.approve(combinator.address, await wCOURAGE.balanceOf(accounts[0]));
    await wWARRIOR.approve(combinator.address, await wWARRIOR.balanceOf(accounts[0]));
    

    try {
      await combinator.claimGameItemFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorManager:INVALID_ID_GC_3");
    }

    await combinator.claimTokenFromTokens(1);

    expect((await wCOURAGE.balanceOf(combinator.address)).toString()).to.be.equal('0', 'fail to check wCOURAGE balance #3');

    expect((await wCOURAGE.balanceOf(accounts[0])).toString()).to.be.equal(web3.utils.toWei('1000200', 'ether'), 'check wCOURAGE');


    try {
      await combinator.claimGameItemFromTokens(1);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsCombinatorTokenGameItem:INVALID_CONFIG");
    }
  });
});