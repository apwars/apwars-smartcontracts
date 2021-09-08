const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsFarmManagerV3 = artifacts.require('APWarsFarmManagerV3');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsFarmManagerOwner = artifacts.require('APWarsFarmManagerOwner');

contract('APWarsFarmManagerOwner', accounts => {

  let wTOKEN = null;
  let wToken1 = null;
  let unitFarmManager = null;
  let burnManager = null;
  let farmManagerOwner = null;

  it('should setup tokens and farm manager', async () => {
    const currentBlock = await web3.eth.getBlockNumber();

    wTOKEN = await APWarsBaseToken.new('wTOKEN', 'wTOKEN');
    wToken1 = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    wToken2 = await APWarsBaseToken.new('wGOLD', 'wGOLD');
    burnManager = await APWarsBurnManager.new();
    unitFarmManager = await APWarsFarmManagerV3.new(wTOKEN.address, accounts[0], burnManager.address, currentBlock);
    farmManagerOwner = await APWarsFarmManagerOwner.new();

    await wTOKEN.transferOwnership(unitFarmManager.address);

    await unitFarmManager.add(
      1000,
      wToken1.address,
      burnManager.address,
      true
    );

    await unitFarmManager.transferOwnership(farmManagerOwner.address);

    try {
      await unitFarmManager.add(
        1000,
        wToken2.address,
        burnManager.address,
        true
      );

      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('Ownable: caller is not the owner');
    }

    await farmManagerOwner.transferOwnership(unitFarmManager.address, accounts[0]);

    await unitFarmManager.add(
      1000,
      wToken2.address,
      burnManager.address,
      true
    );
  });
});