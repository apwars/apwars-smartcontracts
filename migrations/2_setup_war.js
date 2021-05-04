const APWarsUnitToken = artifacts.require("APWarsUnitToken");
const APWarsGoldToken = artifacts.require("APWarsGoldToken");
const APWarsWarMachine = artifacts.require("APWarsWarMachine");
const Collectibles = artifacts.require('APWarsCollectibles');
const BurnManager = artifacts.require('APWarsBurnManagerV2');

module.exports = async (deployer, network, accounts) => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';

  await deployer.deploy(APWarsGoldToken, "wGOLD", "wGOLD");
  const wGOLD = await APWarsGoldToken.deployed();

  await deployer.deploy(APWarsUnitToken, "wWARRIOR", "wWARRIOR", 2, 4, 0);
  const wWARRIOR = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wARCHER", "wARCHER", 5, 1, 0);
  const wARCHER = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wARMOURED-WARRIOR", "wARMOURED-WARRIOR", 15, 15, 0);
  const wARMOUREDWARRIOR = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wCROSSBOWMAN", "wCROSSBOWMAN", 25, 5, 0);
  const wCROSSBOWMAN = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wWIZARD", "wWIZARD", 70, 20, 10);
  const wWIZARD = await APWarsUnitToken.deployed();

  await deployer.deploy(APWarsUnitToken, "wGRUNT", "wGRUNT", 2, 4, 0);
  const wGRUNT = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wORCARCHER", "wORCARCHER", 5, 1, 0);
  const wORCARCHER = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wPIKEORC", "wPIKEORC", 15, 15, 0);
  const wPIKEORC = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wARMOUREDGRUNT", "wARMOUREDGRUNT", 25, 5, 0);
  const wARMOUREDGRUNT = await APWarsUnitToken.deployed();
  await deployer.deploy(APWarsUnitToken, "wSHAMAN", "wSHAMAN", 70, 20, 10);
  const wSHAMAN = await APWarsUnitToken.deployed();

  await deployer.deploy(APWarsWarMachine, "wGOLD", "wGOLD");
  const warMachine = await APWarsWarMachine.deployed();

  const burnManager = await BurnManager.new(accounts[0]);
  const collectibles = await Collectibles.new(burnManager.address, "");

  const externalRandomSourceHash = await warMachine.hashExternalRandomSource(externalRandomSource);
  await warMachine.setup(
    wGOLD.address,
    burnManager.address,
    [
      wWARRIOR.address,
      wARCHER.address,
      wARMOUREDWARRIOR.address,
      wCROSSBOWMAN.address,
      wWIZARD.address,
    ],
    [
      wGRUNT.address,
      wORCARCHER.address,
      wPIKEORC.address,
      wARMOUREDGRUNT.address,
      wSHAMAN.address,
    ],
    collectibles.address,
    [0, 0, 0, 0, 0]
  );

  await warMachine.createWar('War#1', externalRandomSourceHash);

  await wGOLD.mint('10000000000000000000000');
  await wWARRIOR.mint('10000000000000000000000');
  await wARCHER.mint('10000000000000000000000');
  await wARMOUREDWARRIOR.mint('10000000000000000000000');
  await wCROSSBOWMAN.mint('10000000000000000000000');
  await wWIZARD.mint('10000000000000000000000');
  await wGRUNT.mint('10000000000000000000000');
  await wORCARCHER.mint('10000000000000000000000');
  await wPIKEORC.mint('10000000000000000000000');
  await wARMOUREDGRUNT.mint('10000000000000000000000');
  await wSHAMAN.mint('10000000000000000000000');

  console.log('Base contracts:');
  console.log('_______________________________');
  console.log('wGOLD:', wGOLD.address);
  console.log('WarMachine:', warMachine.address);
  console.log('BurnManager:', BurnManager.address);
  console.log('Collectibles:', collectibles.address);

  console.log("\nHumans:");
  console.log('_______________________________');
  console.log('wWARRIOR:', wWARRIOR.address);
  console.log('wARCHER:', wARCHER.address);
  console.log('wARMOURED-WARRIOR:', wARMOUREDWARRIOR.address);
  console.log('wCROSSBOWMAN:', wCROSSBOWMAN.address);
  console.log('wWIZARD:', wWIZARD.address);

  console.log("\nOrcs:");
  console.log('_______________________________');
  console.log('wGRUNT:', wGRUNT.address);
  console.log('wORCARCHER:', wORCARCHER.address);
  console.log('wPIKEORC:', wPIKEORC.address);
  console.log('wARMOUREDGRUNT:', wARMOUREDGRUNT.address);
  console.log('wSHAMAN:', wSHAMAN.address);
};