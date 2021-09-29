const APWarsWorker = artifacts.require('APWarsWorker');
const APWarsWorkerManager = artifacts.require('APWarsWorkerManager');
const Collectibles = artifacts.require('APWarsCollectibles');
const contracts = require('../data/contracts');

module.exports = async (deployer, network, accounts) => {

  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  

  const getContracts = contracts(network);
  const MAX_INT_NUMBER = web3.utils.toBN(2).pow(web3.utils.toBN(256)).sub(web3.utils.toBN(1)).toString();
  // const worker = "0x8cF80184BCA8b0eFa10DB41c9A7A42E73E7806d4";
  // const workerManagerAddress = "0xe7C50D7F76EBa5BD8473E629B00ECA6aeF8D6e95";
  // const smWorker = await APWarsWorker.at(worker);
  // const smWorkerManager = await APWarsWorker.at(workerManagerAddress);
  
  await deployer.deploy(APWarsWorker);
  const worker = await APWarsWorker.deployed();

  await deployer.deploy(APWarsWorkerManager);
  const workerManager = await APWarsWorkerManager.deployed();

  const workerId = 49;
  const minimumBlocks = 1200;
  const reductionRate = 1000;

  const defaultBlocks = 28800;
  const defaultReward = 1;
  const defaultLimit = 100;

  await worker.setup(
      workerId,
      minimumBlocks,
      reductionRate,
      workerManager.address,
      getContracts.APWarsCollectibles
  );

  await workerManager.setup(defaultBlocks, defaultReward, defaultLimit, getContracts.APWarsCollectibles, []);

  // const collectibles = await Collectibles.at(getContracts.APWarsCollectibles);
  // await collectibles.mint(worker.address, workerId, MAX_INT_NUMBER, '0x0');


  console.log(`worker ${worker.address}`);
  console.log(`workerManager ${workerManager.address}`);
};
