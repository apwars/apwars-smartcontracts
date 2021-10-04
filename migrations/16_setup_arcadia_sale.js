const APWarsLandSale = artifacts.require('APWarsLandSale');
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);

  const MAX_INT_NUMBER = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1)).toString();
  const SEND_TICKET = 1000;

  const contractCollectibles = getContracts.APWarsCollectibles;
  const collectibles = await Collectibles.at(contractCollectibles);

  _idTickets = [58, 59, 60, 61, 62];
  _priceTickets = [
    web3.utils.toWei('150', 'ether'),
    web3.utils.toWei('100', 'ether'),
    web3.utils.toWei('100', 'ether'),
    web3.utils.toWei('50', 'ether'),
    web3.utils.toWei('50', 'ether'),
  ];

  await deployer.deploy(
    APWarsLandSale, 
    getContracts.wLAND,
    getContracts.busd,
    getContracts.APWarsCollectibles,
    getContracts.devAddress,
    _idTickets,
    _priceTickets
  );

  const landSale = await APWarsLandSale.deployed();

  for (id in _idTickets) {
    // await collectibles.mint(accounts[0], _idTickets[id], MAX_INT_NUMBER, '0x0');
    await collectibles.safeTransferFrom(accounts[0], landSale.address, _idTickets[id], SEND_TICKET, "0x0", {
      from: accounts[0],
    });
  }

  console.log(`\n landSale: ${landSale.address}`);

};
