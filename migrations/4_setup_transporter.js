const APWarsGoldToken = artifacts.require("APWarsGoldToken");
const APWarsCollectibles = artifacts.require("APWarsCollectibles");
const APWarsNFTTransporter = artifacts.require("APWarsNFTTransporter");

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  const collectibles = await APWarsCollectibles.deployed();
  await deployer.deploy(APWarsNFTTransporter);
  const transporter = await APWarsNFTTransporter.deployed();
  const wGOLD = await APWarsGoldToken.deployed();
  await transporter.setup(accounts[9], '10000000000000000000', wGOLD.address, collectibles.address, [16], ['5000000000000000000']);
  console.log("\n Transporter:");
  console.log("Address:", transporter.address);

};
