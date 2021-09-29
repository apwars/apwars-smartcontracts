const APWarsWarMachineV3 = artifacts.require("APWarsWarMachineV3");
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {

  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);

  await deployer.deploy(APWarsWarMachineV3);
  const warMachine = await APWarsWarMachineV3.new();
  const externalRandomSource = '0x7aa8c713c524f009f59a8d85c6d9f5f47117f03d5a4df456dea6fec11796fd83';
  const externalRandomSourceHash = await warMachine.hashExternalRandomSource(externalRandomSource);

  const setup = {
    wGOLD: getContracts.wGOLD,
    burnManager: getContracts.APWarsBurnManager,
    teamA: [],
    teamB: [],
    collectibles: getContracts.APWarsCollectibles,
    collectiblesNFTs: [2, 3, 4, 5, 6],
  }

  getContracts.units.map(unit => {
    if (unit.team === 1) {
      setup.teamA.push(unit.contract);
    }
    if (unit.team === 2) {
      setup.teamB.push(unit.contract);
    }
  });

  await warMachine.setup(
    setup.wGOLD,
    setup.burnManager,
    setup.teamA,
    setup.teamB,
    setup.collectibles,
    setup.collectiblesNFTs
  );

  await warMachine.createWar('War3', externalRandomSourceHash);

  console.log('WarMachine:', warMachine.address);
  console.log('externalRandomSource:', externalRandomSource);
  console.log('externalRandomSourceHash:', externalRandomSourceHash);

  console.log(setup);
};


