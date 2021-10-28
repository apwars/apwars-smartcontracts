const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');
const APWarsTokenTransfer = artifacts.require('APWarsTokenTransfer');
const APWarsLandToken = artifacts.require('APWarsLandToken');


module.exports = async (deployer) => {

  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  await deployer.deploy(APWarsCollectiblesTransfer);
  const collectiblesTransfer = await APWarsCollectiblesTransfer.deployed();

  await deployer.deploy(APWarsTokenTransfer);
  const tokenTransfer = await APWarsTokenTransfer.deployed();


  console.log(`tokenTransfer ${tokenTransfer.address}`);
  console.log(`collectiblesTransfer ${collectiblesTransfer.address}`);


};
