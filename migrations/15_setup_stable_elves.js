const APWarsUnitTokenV2 = artifacts.require('APWarsUnitTokenV2');

module.exports = async (deployer) => {

  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const INITIAL_MINT = web3.utils.toWei("100000000", "ether");

  await deployer.deploy(APWarsUnitTokenV2, "wELK-RIDER", "wELK-RIDER", 250, 90, 0);
  var contract = await APWarsUnitTokenV2.deployed();
  await contract.mint(INITIAL_MINT);

  console.log(`contract ${contract.address}`);
};
