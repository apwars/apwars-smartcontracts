const APWarsUnitToken = artifacts.require("APWarsUnitToken");
const APWarsFarmManagerV3 = artifacts.require("APWarsFarmManagerV3");
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {

  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const getContracts = contracts(network);

  const INITIAL_MINT = web3.utils.toWei("1000", "ether");
  const DEV_ADDR = getContracts.devAddress; // accounts[8];
  const TOKEN_PER_BLOCK = web3.utils.toWei("0", "ether");
  const ALLOC_POINT = 100; // 1x = 100
  const wGOLD = getContracts.wGOLD;
  const wCOURAGE = getContracts.wCOURAGE;
  const BURN_MANAGER = "0xBeC25BD8b102761ab70bd821181A4F679C6EdC58";
  const WITH_UPDATE = true;

  const troops = [
    // {
    //   name: "wPIKE-ELF",
    //   strength: 6,
    //   defense: 10,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: web3.utils.toWei("2", "ether"),
    //   startBlock: 0,
    //   lpToken: wGOLD,
    // },
    // {
    //   name: "wELVEN-ARCHER",
    //   strength: 12,
    //   defense: 6,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: web3.utils.toWei("2", "ether"),
    //   startBlock: 0,
    //   lpToken: wGOLD,
    // },
    {
      name: "wARMORED-ELF",
      strength: 25,
      defense: 25,
      improvement: 0,
      unitToken: {},
      farmManagerV3: {},
      tokenPerBlock: web3.utils.toWei("1", "ether"),
      startBlock: 0,
      lpToken: wGOLD,
    },
    {
      name: "wBLADEMASTER",
      strength: 40,
      defense: 10,
      improvement: 0,
      unitToken: {},
      farmManagerV3: {},
      tokenPerBlock: web3.utils.toWei("1", "ether"),
      startBlock: 0,
      lpToken: wGOLD,
    },
  ];

  const print = () => {
    troops.map(trooper => {
      console.log(`[${trooper.name}] Contracts:`);
      console.log(`Token: ${trooper.unitToken.address}`);
      console.log(`FarmManagerV3: ${trooper.farmManagerV3.address}`);
      console.log('');
    })
  };

  for (let index = 0; index < troops.length; index++) {
    try {
      const trooper = troops[index];
      await deployer.deploy(APWarsUnitToken, trooper.name, trooper.name, trooper.strength, trooper.defense, trooper.improvement);
      trooper.unitToken = await APWarsUnitToken.deployed();
      await trooper.unitToken.mint(INITIAL_MINT);
      await deployer.deploy(APWarsFarmManagerV3, trooper.unitToken.address, DEV_ADDR, trooper.tokenPerBlock, trooper.startBlock);
      trooper.farmManagerV3 = await APWarsFarmManagerV3.deployed();
      await trooper.farmManagerV3.add(ALLOC_POINT, trooper.lpToken, BURN_MANAGER, WITH_UPDATE);
      await trooper.unitToken.transferOwnership(trooper.farmManagerV3.address);
    } catch (error) {
      console.log(error);
    }
  }

  print();
};
