const APWarsCombinator = artifacts.require("APWarsCombinator");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  const getContracts = contracts(network);
  const contractCollectibles = getContracts.APWarsCollectiblesTest;
  const collectibles = await Collectibles.at(contractCollectibles);
  const timeBlock = 30;
  const maxMultiple = 1;
  const isEnabled = true;
  const newItems = [4, 5, 6, 7];
  const MAX_INT_NUMBER = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1)).toString();
  const amount = MAX_INT_NUMBER;
  const configCombinatorManager = [
    {
      tier: 1,
      idCollectibles: newItems[0],
      tokenAQty: '10',
      tokenBQty: '40',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    {
      tier: 2,
      idCollectibles: newItems[1],
      tokenAQty: '20',
      tokenBQty: '60',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    {
      tier: 3,
      idCollectibles: newItems[2],
      tokenAQty: '30',
      tokenBQty: '50',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    // {
    //   tier: 4,
    //   idCollectibles: newItems[3],
    //   tokenAQty: '400',
    //   tokenBQty: '300',
    //   tokenABurningRate: '0',
    //   tokenAFeeRate: '10000',
    //   tokenBBurningRate: '0',
    //   tokenBFeeRate: '0',
    //   maxMultiple: maxMultiple,
    // },
  ];

  // Config set combinatorManager
  const setup = {
    feeAddress: getContracts.feeAddress,
    wGOLD: getContracts.wGOLD,
    burnManager: getContracts.APWarsBurnManagerV2,
    collectibles: contractCollectibles,
    units: []
  }

  setup.units = getContracts.units.map(unit => {
    const config = configCombinatorManager.find(config => config.tier === unit.tier);
    return { ...config, ...unit };
  });

  // create combinator and combinatorManager
  await deployer.deploy(APWarsCombinator);
  const combinator = await APWarsCombinator.deployed();
  await deployer.deploy(APWarsCombinatorManager);
  const combinatorManager = await APWarsCombinatorManager.deployed();
  await combinator.setup(setup.feeAddress, setup.burnManager, combinatorManager.address);

  console.log("create new game items for combinator");

  // create new game items for combinator
  await collectibles.mint(combinator.address, newItems[0], amount, '0x0');
  console.log(`collectibles mint id: ${newItems[0]}`);
  await collectibles.mint(combinator.address, newItems[1], amount, '0x0');
  console.log(`collectibles mint id: ${newItems[1]}`);
  await collectibles.mint(combinator.address, newItems[2], amount, '0x0');
  console.log(`collectibles mint id: ${newItems[2]}`);
  await collectibles.mint(combinator.address, newItems[3], amount, '0x0');
  console.log(`collectibles mint id: ${newItems[3]}`);

  // config set combinator
  let idCombinator = 0;
  let printsUnits = [];

  for (let unit in setup.units) {
    const unitInfo = setup.units[unit];
    idCombinator++;
    printsUnits.push({ unit: unitInfo.name, idCombinator: idCombinator });
    await combinatorManager.setupCombinator(idCombinator, timeBlock, unitInfo.maxMultiple, isEnabled);
    await combinatorManager.setupTokenA(
      idCombinator,
      setup.wGOLD,
      web3.utils.toWei(unitInfo.tokenAQty, 'ether'),
      unitInfo.tokenABurningRate,
      unitInfo.tokenAFeeRate,
    );
    await combinatorManager.setupTokenB(
      idCombinator,
      unitInfo.contract,
      web3.utils.toWei(unitInfo.tokenBQty, 'ether'),
      unitInfo.tokenBBurningRate,
      unitInfo.tokenBFeeRate,
    );
    await combinatorManager.setupGameItemC(
      idCombinator,
      setup.collectibles,
      unitInfo.idCollectibles,
      1
    );
    console.log(`config set combinator: ${unitInfo.name}`);
  }

  console.log(`\n Combinator: ${combinator.address}`);
  console.log(`CombinatorManager: ${combinatorManager.address}`);
  console.log("");
  printsUnits.map(print => {
    console.log(`Unit: ${print.unit}`);
    console.log(`idCombinator: ${print.idCombinator} \n`);
  });

};
