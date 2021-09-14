const APWarsUnitToken = artifacts.require("APWarsUnitToken");
const APWarsFarmManagerV3 = artifacts.require("APWarsFarmManagerV3");

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  const INITIAL_MINT = web3.utils.toWei("1000", "ether");
  const DEV_ADDR = "0x63ada67b95de4fa6fedcbd5435cf40bdeeb55fb6"; // accounts[8];
  // const FEE_ADDRESS = accounts[9];
  const TOKEN_PER_BLOCK = web3.utils.toWei("0", "ether");
  const START_BLOCK = 0;
  const ALLOC_POINT = 100; // 1x = 100
  const wGOLD = "0x7Ab6eedd9443e0e98E5Ea93667CA5B250b8ddA51";
  const wCOURAGE = "0x5f51a3ce7f2233777328866f477e86a91ca9ddec";
  const LP_TOKEN = wCOURAGE;
  const BURN_MANAGER = "0x192530A89FF2ADDD01A487aD6a41c8dCE3B5Ca26";
  const WITH_UPDATE = true;

  const troops = [
    // {
    //   name: "wSKELETON-WARRIOR",
    //   strength: 3,
    //   defense: 5,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wHOUND",
    //   strength: 8,
    //   defense: 2,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wUNDEAD-ARCHER",
    //   strength: 35,
    //   defense: 8,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wUNDEAD-PIKEMAN",
    //   strength: 22,
    //   defense: 22,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wWITCH",
    //   strength: 70,
    //   defense: 20,
    //   improvement: 10,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wDEATH-KNIGHT",
    //   strength: 150,
    //   defense: 50,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wWARG",
    //   strength: 150,
    //   defense: 50,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
    // {
    //   name: "wHORSEMAN",
    //   strength: 150,
    //   defense: 50,
    //   improvement: 0,
    //   unitToken: {},
    //   farmManagerV3: {},
    //   tokenPerBlock: TOKEN_PER_BLOCK,
    //   startBlock: START_BLOCK,
    // },
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
      await trooper.farmManagerV3.add(ALLOC_POINT, LP_TOKEN, BURN_MANAGER, WITH_UPDATE);
      await trooper.unitToken.transferOwnership(trooper.farmManagerV3.address);
    } catch (error) {
      console.log(error);
    }
  }

  print();
};
