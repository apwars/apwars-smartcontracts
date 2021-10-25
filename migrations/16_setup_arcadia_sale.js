const APWarsLandSale = artifacts.require('APWarsLandSale');
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  // if (process.env.SKIP_MIGRATION === 'true') {
  //   return;
  // }

  const getContracts = contracts(network);

  const MAX_INT_NUMBER = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1)).toString();
  const SEND_TICKET = 1000;

  const contractCollectibles = getContracts.APWarsCollectibles;
  const collectibles = await Collectibles.at(contractCollectibles);

  // 58 - Temple
  // 59 - Watch Tower
  // 60 - Market
  // 61 - Hideout
  // 62 - Village

  _idTickets = [58, 59, 60, 61, 62];
  _priceTickets = [
    web3.utils.toWei('375', 'ether'),
    web3.utils.toWei('375', 'ether'),
    web3.utils.toWei('1200', 'ether'),
    web3.utils.toWei('225', 'ether'),
    web3.utils.toWei('10', 'ether'),
  ];

  _sendTickets = [10, 10, 5, 15, 0];

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

  // const landSale = await APWarsLandSale.at("0xba159010cDf6A83bB3f491e37dE264406dDeDDFD");

  // await landSale.setup(
  //   getContracts.wLAND,
  //   getContracts.busd,
  //   getContracts.APWarsCollectibles,
  //   getContracts.devAddress,
  //   _idTickets,
  //   _priceTickets
  // );

  // for (id in _idTickets) {
  //   // await collectibles.mint(accounts[0], _idTickets[id], MAX_INT_NUMBER, '0x0');
  //   if (_sendTickets[id] > 0) {
  //     console.log(`idTicket ${_idTickets[id]}, sendTicket ${_sendTickets[id]}`);
  //     await collectibles.safeTransferFrom(accounts[0], landSale.address, _idTickets[id], _sendTickets[id], "0x0", {
  //       from: accounts[0],
  //     });
  //   }
  // }

  console.log(`\n landSale: ${landSale.address}`);

};
