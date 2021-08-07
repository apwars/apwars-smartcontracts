const APWarsLandToken = artifacts.require("APWarsLandToken");
const APWarsLandPrivateSale = artifacts.require("APWarsLandPrivateSale");
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);
  await deployer.deploy(APWarsLandToken, "wLAND", "wLAND");
  const wLAND = await APWarsLandToken.deployed();
  const contractCollectibles = getContracts.APWarsCollectiblesTest;
  const collectibles = await Collectibles.at(contractCollectibles);

  const busd = getContracts.busd;
  const worldTicketId = 38;
  const worldTicketAmount = 2;
  const clanTicketId = 39;
  const clanTicketAmount = 50;
  const dev = getContracts.devAddress;
  const vestingEndBlock = "11189382";
  const vestingIntervalInBlocks = "3600";

  /* Create world and clan */
  await collectibles.mint(contractCollectibles, worldTicketId, worldTicketAmount, '0x0');
  console.log(`collectibles mint id: ${worldTicketId}`);
  await collectibles.mint(contractCollectibles, clanTicketId, clanTicketAmount, '0x0');
  console.log(`collectibles mint id: ${clanTicketId}`);

  await deployer.deploy(APWarsLandPrivateSale, wLAND.address, busd, contractCollectibles, worldTicketId, clanTicketId, dev, vestingEndBlock, vestingIntervalInBlocks);
  const landPrivateSale = await APWarsLandPrivateSale.deployed();

  console.log(`\n wLAND: ${wLAND.address}`);
  console.log(`landPrivateSale: ${landPrivateSale.address}`);
  console.log("");

};
