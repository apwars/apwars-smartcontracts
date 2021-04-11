const APWarsCollectibles = artifacts.require("APWarsCollectibles");
const APWarsBurnManager = artifacts.require("APWarsBurnManager");

module.exports = async (deployer) => {
  await deployer.deploy(APWarsBurnManager);
  const instance = await APWarsBurnManager.deployed();
  await deployer.deploy(APWarsCollectibles, instance.address, "URI");
};
