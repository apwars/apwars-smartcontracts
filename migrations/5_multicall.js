const Multicall = artifacts.require("Multicall");

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(Multicall);
};
