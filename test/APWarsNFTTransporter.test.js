const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsMarketNFTSwapEscrow = artifacts.require('APWarsMarketNFTSwapEscrow');
const APWarsNFTTransporter = artifacts.require('APWarsNFTTransporter');

var sleep = require('sleep');

contract.only('APWarsNFTTransporter', accounts => {
  let burnManager = null;
  let wGOLD = null;
  let collectibles = null;
  let escrow = null;
  let transporter = null;

  it('should deploy the contracts', async () => {
    burnManager = await APWarsBurnManager.new(accounts[2]);
    wGOLD = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    collectibles = await APWarsCollectibles.new(burnManager.address, 'URI');

    await wGOLD.mint(accounts[0], web3.utils.toWei('100', 'ether'));
    await wGOLD.mint(accounts[2], web3.utils.toWei('100', 'ether'));
    await wGOLD.mint(accounts[3], web3.utils.toWei('100', 'ether'));

    await collectibles.mint(accounts[1], 7, 6, '0x0');
    await collectibles.mint(accounts[2], 10, 1, '0x0');
    await collectibles.mint(accounts[3], 11, 1, '0x0');
    await collectibles.mint(accounts[3], 12, 10, '0x0');

    escrow = await APWarsMarketNFTSwapEscrow.new();
    transporter = await APWarsNFTTransporter.new();
  });

  it('should setup system escrow', async () => {
    await escrow.setup(accounts[9], 250, [wGOLD.address]);

    expect(await escrow.getFeeAddress()).to.be.equal(accounts[9]);
    expect((await escrow.getSwapFeeRate()).toString()).to.be.equal('250');

    const allowedTokens = await escrow.getAllowedTokens();

    expect(allowedTokens.length).to.be.equal(1);
    expect(allowedTokens[0]).to.be.equal(wGOLD.address);
  });

  it('should setup system transporter', async () => {
    try {
      await transporter.setup(accounts[9], web3.utils.toWei('10', 'ether'), wGOLD.address, collectibles.address, ["12"], [web3.utils.toWei('15', 'ether')]);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsNFTTransporter:FAIL_PRICE_GREATER_THAN_FEEAMOUNT');
    }

    try {
      await transporter.setup(accounts[9], web3.utils.toWei('10', 'ether'), wGOLD.address, collectibles.address, ["12", "13"], [web3.utils.toWei('5', 'ether')]);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('APWarsNFTTransporter:FAIL_LENGTH_PRICE_AND_ALLOWEDFEE');
    }

    await transporter.setup(accounts[9], web3.utils.toWei('10', 'ether'), wGOLD.address, collectibles.address, ["12"], [web3.utils.toWei('5', 'ether')]);

    const resultAccount0 = await transporter.getFeeAmount(accounts[0]);
    const resultAccount3 = await transporter.getFeeAmount(accounts[3]);

    expect(await transporter.getFeeAddress()).to.be.equal(accounts[9]);
    expect(resultAccount0.currentFeeAmount.toString()).to.be.equal('10000000000000000000');
    expect(resultAccount0.nftId.toString()).to.be.equal('0');
    expect(resultAccount3.currentFeeAmount.toString()).to.be.equal('5000000000000000000');
    expect(resultAccount3.nftId.toString()).to.be.equal('12');
    expect((await transporter.getFeeTokenAddress()).toString()).to.be.equal(wGOLD.address);

  });

  it('should send an NFT', async () => {
    const tokenId = 10;
    try {
      await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, { from: accounts[2] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('BEP20: transfer amount exceeds allowance');
    }

    await wGOLD.approve(transporter.address, await wGOLD.balanceOf(accounts[2]), { from: accounts[2] });

    try {
      await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, { from: accounts[2] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('ERC1155: caller is not owner nor approved');
    }

    await collectibles.setApprovalForAll(transporter.address, true, { from: accounts[2] });

    await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, { from: accounts[2] });

    const balanceNFT = await collectibles.balanceOf(accounts[4], tokenId);
    expect(balanceNFT.toString()).to.be.equal('1');

    const balancewGOLD = await wGOLD.balanceOf(accounts[2]);
    expect(balancewGOLD.toString()).to.be.equal('90000000000000000000');

  });

  it('should send an NFT using another NFT as fee', async () => {
    const tokenId = 12;

    const feeAmount = await transporter.getFeeAmount(accounts[3]);
    expect(feeAmount.currentFeeAmount.toString()).to.be.equal(web3.utils.toWei('5', 'ether'));
    expect(feeAmount.nftId.toString()).to.be.equal('12');
    const balancewGOLDAccount3 = web3.utils.fromWei((await wGOLD.balanceOf(accounts[3])).toString());

    await wGOLD.approve(transporter.address, await wGOLD.balanceOf(accounts[3]), { from: accounts[3] });
    await collectibles.setApprovalForAll(transporter.address, true, { from: accounts[3] });
    await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, { from: accounts[3] });

    const balanceNFT = await collectibles.balanceOf(accounts[9], tokenId);
    expect(balanceNFT.toString()).to.be.equal('1');

    const currentFeeAmount = web3.utils.fromWei(feeAmount.currentFeeAmount.toString());
    expect((balancewGOLDAccount3 - currentFeeAmount).toString()).to.be.equal(web3.utils.fromWei((await await wGOLD.balanceOf(accounts[3])).toString()));

  });

});
