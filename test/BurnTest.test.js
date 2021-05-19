const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBurnManager = artifacts.require('APWarsBurnManagerV2');
const APWarsGoldToken = artifacts.require('APWarsGoldToken');

contract('BurnTest', accounts => {
  it('should mint and burn', async () => {
    wGOLD = await APWarsGoldToken.new('wGOLD', 'wGOLD');
    await wGOLD.mint(accounts[0], '1000000');
    let totalSupply = await wGOLD.totalSupply();
    await wGOLD.burn('1000000');
    totalSupply = await wGOLD.totalSupply();
    expect(totalSupply.toString()).to.be.equal('0');
  });
});