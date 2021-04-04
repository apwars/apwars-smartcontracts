const APWar = artifacts.require("APWar");

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(APWar);
};
