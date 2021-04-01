const APWar = artifacts.require("MultiCall");

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(APWar);
};
