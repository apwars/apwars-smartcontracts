const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsMarketNFTSwapEscrow = artifacts.require('APWarsMarketNFTSwapEscrow');
const APWarsNFTTransporter = artifacts.require('APWarsNFTTransporter');

var sleep = require('sleep');

contract('APWarsNFTTransporter', accounts => {
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
    await transporter.setup(accounts[9], web3.utils.toWei('10', 'ether'), wGOLD.address);

    expect(await transporter.getFeeAddress()).to.be.equal(accounts[9]);
    expect((await transporter.getFeeAmount()).toString()).to.be.equal('10000000000000000000');
    expect((await transporter.getFeeTokenAddress()).toString()).to.be.equal(wGOLD.address);

  });

  it('should send a NFT', async () => {
    const tokenId = 10;
    try {
      await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, {from: accounts[2]});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('BEP20: transfer amount exceeds allowance');
    }

    await wGOLD.approve(transporter.address, await wGOLD.balanceOf(accounts[2]), {from: accounts[2]});

    try {
      await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, {from: accounts[2]});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('ERC1155: caller is not owner nor approved');
    }

    await collectibles.setApprovalForAll(transporter.address, true, {from: accounts[2]});

    await transporter.sendNFT(collectibles.address, accounts[4], tokenId, 1, {from: accounts[2]});

    const balanceNFT = await collectibles.balanceOf(accounts[4], tokenId);
    expect(balanceNFT.toString()).to.be.equal('1');

    const balancewGOLD = await wGOLD.balanceOf(accounts[2]);
    expect(balancewGOLD.toString()).to.be.equal('90000000000000000000');

  });

});
