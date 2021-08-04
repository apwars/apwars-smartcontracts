const APWarsWarMachineV2 = artifacts.require("APWarsWarMachineV2");
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {

  const getContracts = contracts(network);

  await deployer.deploy(APWarsWarMachineV2);
  const warMachine = await APWarsWarMachineV2.new();
  const externalRandomSource = '0x451de2aaf1d2e9ecaa1a3ca228d0976fc561cfe5e971774b4ada47624def15b6';
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

  await warMachine.createWar('War#2', externalRandomSourceHash);

  console.log('WarMachine:', warMachine.address);
  console.log('externalRandomSource:', externalRandomSource);
  console.log('externalRandomSourceHash:', externalRandomSourceHash);

  console.log(setup);
};


