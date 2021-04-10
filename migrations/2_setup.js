const APWarsBurnManager = artifacts.require("APWarsBurnManager");
const APWarsFarmManagerV2 = artifacts.require("APWarsFarmManagerV2");
const APWarsGoldToken = artifacts.require("APWarsGoldToken");
const Collectibles = artifacts.require("APWarsCollectibles");
const Multicall = artifacts.require("Multicall");

module.exports = async (deployer, network, accounts) => {
  const burnManagerInstance = await deployer.deploy(APWarsBurnManager);
  const multicallInstance = await deployer.deploy(Multicall);

  const bnbToken = await deployer.deploy(APWarsGoldToken, 'BNB', 'BNB');
  await bnbToken.mint(accounts[0], '10000000000000000000000000');
  const busdToken = await deployer.deploy(APWarsGoldToken, 'BUSD', 'BUSD');
  await busdToken.mint(accounts[0], '10000000000000000000000000');
  const daiToken = await deployer.deploy(APWarsGoldToken, 'DAI', 'DAI');
  await daiToken.mint(accounts[0], '10000000000000000000000000');
  const usdcToken = await deployer.deploy(APWarsGoldToken, 'DAI', 'DAI');
  await usdcToken.mint(accounts[0], '10000000000000000000000000');

  await deployer.deploy(APWarsGoldToken, 'wGOLD', 'wGOLD');

  const wGOLDInstance = await APWarsGoldToken.deployed();
  await wGOLDInstance.mint(accounts[0], '10000000000000000000000000');

  const currentBlockNumber = await web3.eth.getBlockNumber();
  await deployer.deploy(APWarsFarmManagerV2, wGOLDInstance.address, accounts[0], accounts[0], '1000000000000000000', currentBlockNumber);
  const farmManagerInstance = await APWarsFarmManagerV2.deployed();
  farmManagerInstance.add(1000, bnbToken.address, 0, true);
  farmManagerInstance.add(1000, busdToken.address, 0, true);

  await wGOLDInstance.transferOwnership(farmManagerInstance.address);

  await deployer.deploy(Collectibles, 'http://localhost');
  const collectiblesInstance = await Collectibles.deployed();
  await collectiblesInstance.setDevAddress(accounts[0]);
  await collectiblesInstance.setMaxSupply(0, 10);
  await collectiblesInstance.setMaxSupply(1, 100);
  await collectiblesInstance.setMaxSupply(2, 1000);
  await collectiblesInstance.setMaxSupply(3, 10000);
  await collectiblesInstance.setMaxSupply(4, 100000);
  await collectiblesInstance.setMaxSupply(5, 1000000);
  await collectiblesInstance.setMaxSupply(6, 10000000);
  await collectiblesInstance.setMaxSupply(7, 100000000);
  await collectiblesInstance.setMaxSupply(8, 1000000000);
  await collectiblesInstance.setMaxSupply(9, 10000000000);
  await collectiblesInstance.setMaxSupply(10, 100000000000);

  console.log('Contract addresses:');
  console.log('wGOLD:', wGOLDInstance.address);
  console.log('FarmManager:', farmManagerInstance.address);
  console.log('Collectibles:', collectiblesInstance.address);
  console.log('Multicall:', multicallInstance.address);
  console.log('BNB:', bnbToken.address);
  console.log('BUSD:', busdToken.address);
  console.log('USDC:', usdcToken.address);
  console.log('DAI:', daiToken.address);
};

