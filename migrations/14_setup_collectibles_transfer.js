const APWarsCollectiblesTransfer = artifacts.require('APWarsCollectiblesTransfer');

module.exports = async (deployer) => {

  // if (process.env.SKIP_MIGRATION === 'true') {
  //   return;
  // }

  await deployer.deploy(APWarsCollectiblesTransfer);
  const collectiblesTransfer = await APWarsCollectiblesTransfer.deployed();

  console.log(`collectiblesTransfer ${collectiblesTransfer.address}`);
};
