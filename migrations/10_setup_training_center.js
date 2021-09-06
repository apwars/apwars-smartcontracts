const APWarsCombinator = artifacts.require("APWarsCombinator");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");
const APWarsUnitTokenV2 = artifacts.require("APWarsUnitTokenV2");
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  const getContracts = contracts(network);
  const INITIAL_MINT = web3.utils.toWei("100000000", "ether");
  const timeBlock = 90;
  const maxMultiple = 1;
  const isEnabled = true;

  const troops = [
    {
      name: "wDEATH-KNIGHT",
      strength: 200,
      defense: 60,
      improvement: 0,
      unitToken: {},
      unitCombinator: "0x8df7145Fc3a1B7BC590a229737d8c39bD058Ab49",
    },
    {
      name: "wWARG",
      strength: 150,
      defense: 50,
      improvement: 0,
      unitToken: {},
      unitCombinator: "0x7b58Fc38F4EcD3f14F0189307881E63d79490A07",
    },
    {
      name: "wHORSEMAN",
      strength: 150,
      defense: 50,
      improvement: 0,
      unitToken: {},
      unitCombinator: "0x9DB33bFDBCE63aC62717950ACea4cf030BDCFD92",
    },
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

  // Create units
  for (let index = 0; index < troops.length; index++) {
    try {
      const trooper = troops[index];
      await deployer.deploy(APWarsUnitTokenV2, trooper.name, trooper.name, trooper.strength, trooper.defense, trooper.improvement);
      trooper.unitToken = await APWarsUnitTokenV2.deployed();
      await trooper.unitToken.mint(INITIAL_MINT);
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

  // create combinator and combinatorManager
  await deployer.deploy(APWarsCombinator);
  const combinator = await APWarsCombinator.deployed();
  await deployer.deploy(APWarsCombinatorManager);
  const combinatorManager = await APWarsCombinatorManager.deployed();
  await combinator.setup(setup.feeAddress, setup.burnManager, combinatorManager.address);

  console.log("create new game items for combinator");

  // config set combinator
  let idCombinator = 0;
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
