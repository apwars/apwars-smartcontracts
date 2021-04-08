const APWarsBurnManager = artifacts.require("APWarsBurnManager");
const APWar = artifacts.require("APWar");

module.exports = async (deployer) => {
  await deployer.deploy(APWarsBurnManager);
  await deployer.deploy(APWar);
};
