const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsLandToken = artifacts.require('APWarsLandToken');
const APWarsLandPrivateSale = artifacts.require('APWarsLandPrivateSale');

var sleep = require('sleep');

let wLAND = null;
let busd = null;
let privateSale = null;
let blockNumber;

const deployContracts = async (accounts) => {
  blockNumber = await web3.eth.getBlockNumber();

  wLAND = await APWarsLandToken.new('wLAND', 'wLAND');
  busd = await APWarsBaseToken.new('BUSD', 'BUSD');
  privateSale = await APWarsLandPrivateSale.new(
    wLAND.address,
    busd.address,
    accounts[3],
    blockNumber + 15,
    5
  );

  await busd.mint(accounts[1], web3.utils.toWei('1000000', 'ether'));
  await busd.mint(accounts[2], web3.utils.toWei('1000000', 'ether'));
  await wLAND.transfer(privateSale.address, web3.utils.toWei('1500000', 'ether'));
}

contract('APWarswLANDPrivateSale', accounts => {
  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it('should buy wLAND', async () => {
    await privateSale.setupWhiteList([accounts[1], accounts[2]], true);

    await busd.approve(privateSale.address, await busd.balanceOf(accounts[1]), { from: accounts[1] });
    await busd.approve(privateSale.address, await busd.balanceOf(accounts[2]), { from: accounts[2] });

    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await privateSale.buywLAND(web3.utils.toWei('1000', 'ether'), { from: accounts[2] });

    expect((await busd.balanceOf(accounts[3])).toString()).to.be.equal(web3.utils.toWei((1900 * 0.5).toString(), 'ether'), "fail to test accounts[0] busd balance");
    
    let info = await privateSale.shares(accounts[1]);

    expect(info.investedAmount.toString()).to.be.equal(web3.utils.toWei('450', 'ether'));
    expect(info.wLANDAmount.toString()).to.be.equal(web3.utils.toWei('900', 'ether'));
    expect(info.remainingAmount.toString()).to.be.equal(web3.utils.toWei('900', 'ether'));
    expect(info.claimedAmount.toString()).to.be.equal(web3.utils.toWei('0', 'ether'));
    expect(info.claims.toString()).to.be.equal('0');
    expect(info.nextBlock.toString()).to.be.equal((blockNumber + 15).toString(), 'ether');
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
});