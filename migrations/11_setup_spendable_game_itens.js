const APWarsCombinatorTokenGameItem = artifacts.require("APWarsCombinatorTokenGameItem");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  // if (process.env.SKIP_MIGRATION === 'true') {
  //   return;
  // }
  
  const getContracts = contracts(network);
  const contractCollectibles = getContracts.APWarsCollectibles;
  const collectibles = await Collectibles.at(contractCollectibles);
  const timeBlock = 30;
  const maxMultiple = 1;
  const isEnabled = true;
  const newItems = [40, 41, 42, 43];
  const MAX_INT_NUMBER = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1)).toString();
  const amount = MAX_INT_NUMBER;
  
  const configCombinatorManager = [
    {
      idCollectibles: newItems[0],
      idCollectiblesReceived: newItems[0],
      tokenAQty: '9000',
      tokenBQty: '1',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    {
      idCollectibles: newItems[1],
      idCollectiblesReceived: newItems[1],
      tokenAQty: '900000',
      tokenBQty: '1',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    {
      idCollectibles: newItems[2],
      idCollectiblesReceived: newItems[2],
      tokenAQty: '1800000',
      tokenBQty: '1',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
    {
      idCollectibles: newItems[3],
      idCollectiblesReceived: newItems[3],
      tokenAQty: '90000',
      tokenBQty: '1',
      tokenABurningRate: '0',
      tokenAFeeRate: '10000',
      tokenBBurningRate: '0',
      tokenBFeeRate: '0',
      maxMultiple: maxMultiple,
    },
  ];

  // Config set combinatorManager
  const setup = {
    feeAddress: getContracts.feeAddress,
    wCOURAGE: getContracts.wCOURAGE,
    burnManager: getContracts.APWarsBurnManagerV2,
    collectibles: contractCollectibles,
    units: []
  }

  // create combinator and combinatorManager
  await deployer.deploy(APWarsCombinatorTokenGameItem);
  const combinator = await APWarsCombinatorTokenGameItem.deployed();
  await deployer.deploy(APWarsCombinatorManager);
  const combinatorManager = await APWarsCombinatorManager.deployed();
  await combinator.setup(setup.feeAddress, setup.burnManager, combinatorManager.address);

  // 0xCAE00ce5282CF2b559BC45f17c47b2f5d3E20244
  // const combinator = await APWarsCombinatorTokenGameItem.at(getContracts.APWarsCombinatorTokenGameItem);
  // const combinatorManager = await APWarsCombinatorManager.at(getContracts.APWarsCombinatorManager);

  console.log("create new game items for combinator");

  // create new game items for combinator
  // await collectibles.mint(combinator.address, newItems[0], amount, '0x0');
  // console.log(`collectibles mint id: ${newItems[0]}`);
  // await collectibles.mint(combinator.address, newItems[1], amount, '0x0');
  // console.log(`collectibles mint id: ${newItems[1]}`);
  // await collectibles.mint(combinator.address, newItems[2], amount, '0x0');
  // console.log(`collectibles mint id: ${newItems[2]}`);
  // await collectibles.mint(combinator.address, newItems[3], amount, '0x0');
  // console.log(`collectibles mint id: ${newItems[3]}`);

  // config set combinator
  let idCombinator = 0;
  let printsUnits = [];

  for (let unit of configCombinatorManager) {
    const unitInfo = unit;
    console.log(`config set start combinator: ${unitInfo.idCollectibles}`);
    idCombinator++;
    printsUnits.push({ idCollectibles: unitInfo.idCollectibles, idCombinator: idCombinator });
    await combinatorManager.setupCombinator(idCombinator, timeBlock, unitInfo.maxMultiple, isEnabled);
    await combinatorManager.setupTokenA(
      idCombinator,
      setup.wCOURAGE,
      web3.utils.toWei(unitInfo.tokenAQty, 'ether'),
      unitInfo.tokenABurningRate,
      unitInfo.tokenAFeeRate,
    );
    await combinatorManager.setupGameItemB(
      idCombinator,
      setup.collectibles,
      unitInfo.idCollectibles,
      unitInfo.tokenBQty,
      unitInfo.tokenBBurningRate,
      unitInfo.tokenBFeeRate,
    );
    await combinatorManager.setupGameItemC(
      idCombinator,
      setup.collectibles,
      unitInfo.idCollectiblesReceived,
      10,
      0,
      0,
    );

    console.log(`config set end combinator: ${unitInfo.idCollectibles}`);
  }

  console.log(`\n Combinator: ${combinator.address}`);
  console.log(`CombinatorManager: ${combinatorManager.address}`);
  console.log("");
  printsUnits.map(print => {
    console.log(`idCollectibles: ${print.idCollectibles}`);
    console.log(`idCombinator: ${print.idCombinator} \n`);
  });

};
