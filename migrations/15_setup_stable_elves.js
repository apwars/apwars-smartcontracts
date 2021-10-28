const APWarsCombinator = artifacts.require("APWarsCombinator");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");
const APWarsUnitTokenV2 = artifacts.require("APWarsUnitTokenV2");
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  const getContracts = contracts(network);
  const INITIAL_MINT = web3.utils.toWei("1000", "ether");
  const timeBlock = 1200;
  const maxMultiple = 1;
  const isEnabled = true;

  const troops = [
    {
      name: "wELK-RIDER",
      strength: 250,
      defense: 90,
      improvement: 0,
      unitToken: {},
      unitCombinator: "0xE7Cb07032a9b9150a25249709C50b9BD923E445e",
    }
  ];

  configCombinatorManager = {
    tokenAQty: '2200',
    tokenBQty: '100',
    tokenABurningRate: '0',
    tokenAFeeRate: '10000',
    tokenBBurningRate: '9000',
    tokenBFeeRate: '1000',
    maxMultiple: maxMultiple,
  };


  // set combinator and combinatorManager
  const combinator = await APWarsCombinator.at(getContracts.APWarsCombinator);
  const combinatorManager = await APWarsCombinatorManager.at(getContracts.APWarsCombinatorManager);

  // Create units
  for (let index = 0; index < troops.length; index++) {
    try {
      const trooper = troops[index];
      await deployer.deploy(APWarsUnitTokenV2, trooper.name, trooper.name, trooper.strength, trooper.defense, trooper.improvement);
      trooper.unitToken = await APWarsUnitTokenV2.deployed();
      await trooper.unitToken.mint(INITIAL_MINT);
      await trooper.unitToken.grantRole((await trooper.unitToken.MINTER_ROLE()), combinator.address);
    } catch (error) {
      console.log(error);
    }
  }

  // Config set combinatorManager
  const setup = {
    feeAddress: getContracts.feeAddress,
    wCOURAGE: getContracts.wCOURAGE,
    burnManager: getContracts.APWarsBurnManagerV2,
    units: []
  }

  console.log("create new game items for combinator");

  // config set combinator
  let idCombinator = 9;
  let printsUnits = [];

  for (let unit of troops) {
    const unitInfo = unit;
    idCombinator++;
    printsUnits.push({ unit: unitInfo.name, address: unit.unitToken.address, idCombinator: idCombinator });
    await combinatorManager.setupCombinator(idCombinator, timeBlock, configCombinatorManager.maxMultiple, isEnabled);
    await combinatorManager.setupTokenA(
      idCombinator,
      setup.wCOURAGE,
      web3.utils.toWei(configCombinatorManager.tokenAQty, 'ether'),
      configCombinatorManager.tokenABurningRate,
      configCombinatorManager.tokenAFeeRate,
    );
    await combinatorManager.setupTokenB(
      idCombinator,
      unit.unitCombinator,
      web3.utils.toWei(configCombinatorManager.tokenBQty, 'ether'),
      configCombinatorManager.tokenBBurningRate,
      configCombinatorManager.tokenBFeeRate,
    );
    await combinatorManager.setupTokenC(
      idCombinator,
      unit.unitToken.address,
      web3.utils.toWei('100', 'ether'),
      0,
      0,
    );
    console.log(`config set combinator: ${unitInfo.name}`);
  }

  console.log(`\n Combinator: ${combinator.address}`);
  console.log(`CombinatorManager: ${combinatorManager.address}`);
  console.log("");
  printsUnits.map(print => {
    console.log(`Unit: ${print.unit}`);
    console.log(`Address: ${print.address}`);
    console.log(`idCombinator: ${print.idCombinator} \n`);
  });


};
