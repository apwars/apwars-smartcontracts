const APWarsGoldToken = artifacts.require("APWarsGoldToken");
const APWarsNFTTransporter = artifacts.require("APWarsNFTTransporter");

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(APWarsNFTTransporter);
  const transporter = await APWarsNFTTransporter.deployed();
  const wGOLD = await APWarsGoldToken.deployed();
  await transporter.setup(accounts[9], '10000000000000000000', wGOLD.address);
  console.log("\n Transporter:");
  console.log("Address:", transporter.address);

};
