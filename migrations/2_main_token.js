require('dotenv').config()
const BaseToken = artifacts.require("APWarsGoldToken");
const APWarsFarmManagerV2 = artifacts.require('APWarsFarmManagerV2');

module.exports = async (deployer, network, accounts) => {
  const suffix = process.env.TOKEN_SUFFIX;
  const initialSupply = '10000';
  const tokensPerBlock = '1';
  const currentBlock = (await web3.eth.getBlockNumber()) + 100;

  console.log('Deploying base token');
  await deployer.deploy(BaseToken, `APWars Gold Token${suffix}`, `A:GOLD-${suffix}`);
  const instance = await BaseToken.deployed();
  await instance.mint(accounts[0], web3.utils.toWei(initialSupply));
  console.log('Base token deployed');

  console.log(`A:GOLD-${suffix} - ${instance.address}`);
    await deployer.deploy(
      APWarsFarmManagerV2,
      instance.address,
      accounts[0],
      accounts[0],
      web3.utils.toWei(tokensPerBlock),
      currentBlock);
    
    const farmManagerInstance = await APWarsFarmManagerV2.deployed();
    console.log(`A:GOLD-${suffix} farm manager - ${farmManagerInstance.address}`);

    console.log('Transfering ownership to farm manager');
    await instance.transferOwnership(farmManagerInstance.address);
};
