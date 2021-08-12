const APWarsBaseToken = artifacts.require("APWarsBaseToken");
const APWarsLandToken = artifacts.require("APWarsLandToken");
const APWarsWisdowToken = artifacts.require('APWarsWisdowToken');
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

  const wWISDOW = await APWarsWisdowToken.new('wWISDOW', 'wWISDOW');

  const busd = await APWarsBaseToken.new('BUSD', 'BUSD');
  await busd.mint('0xf6375FfD609Fa886803C27260d872CcCfA7d9257', web3.utils.toWei('10000000', 'ether'));
  await busd.mint('0xE256B4b2755Eba57d8C1EC6FB5942a9DeBAF6b3F', web3.utils.toWei('10000000', 'ether'));
  // busd prod 0xe9e7cea3dedca5984780bafc599bd69add087d56
  // bsusdToken = "0xe9e7cea3dedca5984780bafc599bd69add087d56";
  const busdAddress = busd.address; // bsusdToken; //

  const HOUR_INBLOCK = 3600 / 3 / 6;
  const blockNumber = await web3.eth.getBlockNumber();

  const worldTicketId = 59;
  const worldTicketAmount = 2;
  const clanTicketId = 60;
  const clanTicketAmount = 49;
  const dev = getContracts.devAddress;
  const cliffEndBlock = blockNumber + (HOUR_INBLOCK * 2);
  const privateSaleEndBlock = blockNumber + HOUR_INBLOCK;
  const vestingIntervalInBlocks = HOUR_INBLOCK / 6;
  const priorityEndBlock = blockNumber + HOUR_INBLOCK / 2;

  /* Create world and clan */
  if (network !== "bsc") {
    await collectibles.mint(accounts[0], worldTicketId, worldTicketAmount, '0x0');
    console.log(`collectibles mint id: ${worldTicketId}`);
    await collectibles.mint(accounts[0], clanTicketId, clanTicketAmount, '0x0');
    console.log(`collectibles mint id: ${clanTicketId}`);
  }

  await deployer.deploy(
    APWarsLandPrivateSale,
    wLAND.address,
    wWISDOW.address,
    busdAddress,
    contractCollectibles,
    worldTicketId,
    clanTicketId,
    dev,
    cliffEndBlock,
    privateSaleEndBlock,
    vestingIntervalInBlocks,
    priorityEndBlock);
  const landPrivateSale = await APWarsLandPrivateSale.deployed();

  await wLAND.transfer(landPrivateSale.address, web3.utils.toWei('1500000', 'ether'));
  await wWISDOW.grantRole(await wWISDOW.MINTER_ROLE(), landPrivateSale.address);

  /* transfer collectibles */
  await collectibles.safeTransferFrom(accounts[0], landPrivateSale.address, worldTicketId, worldTicketAmount, "0x0", {
    from: accounts[0],
  });
  await collectibles.safeTransferFrom(accounts[0], landPrivateSale.address, clanTicketId, clanTicketAmount, "0x0", {
    from: accounts[0],
  });

  console.log(`\n wLAND: ${wLAND.address}`);
  console.log(`\n wWISDOW: ${wWISDOW.address}`);
  console.log(`\n busd: ${busdAddress}`);
  console.log(`landPrivateSale: ${landPrivateSale.address}`);
  console.log("");
  console.log("setup");
  console.log({
    APWarsLandPrivateSale,
    wLANDAddress: wLAND.address,
    wWISDOWAddress: wWISDOW.address,
    busdAddress,
    contractCollectibles,
    worldTicketId,
    clanTicketId,
    dev,
    cliffEndBlock,
    privateSaleEndBlock,
    vestingIntervalInBlocks,
    priorityEndBlock
  })

};
