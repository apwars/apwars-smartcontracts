const APWarsGoldToken = artifacts.require("APWarsCombinator");
const APWarsCollectibles = artifacts.require("APWarsCombinatorManager");

module.exports = async (deployer, network, accounts) => {
  const feeAddress = "0xf6375FfD609Fa886803C27260d872CcCfA7d9257";
  const burnManager = "0x1a6E3a930be1Ff2fE959FBFc365dAf8045280eAd";
  const wGOLD = "0x3A5c025065a14EF9e834fBD90aeD3876a07c60EA";

  const combinator = await APWarsCombinator.deployed();
  const combinatorManager = await APWarsCombinatorManager.deployed();
  await combinator.setup(feeAddress, burnManager, combinatorManager.address);

  await combinatorManager.setupCombinator(1, 15, 1, true);
  await combinatorManager.setupTokenA(
    1,
    wGOLD,
    web3.utils.toWei('100', 'ether'),
    0,
    0,
  );
  await combinatorManager.setupTokenB(
    1,
    wWARRIOR.address,
    web3.utils.toWei('1000', 'ether'),
    0,
    0
  );
  await combinatorManager.setupGameItemC(
    1,
    collectibles.address,
    10,
    1
  );

};
