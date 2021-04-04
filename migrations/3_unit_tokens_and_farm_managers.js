const UnitToken = artifacts.require('APWarsUnitToken');
const APWarsFarmManagerV2 = artifacts.require('APWarsFarmManagerV2');

module.exports = async (deployer, network, accounts) => {
  const suffix = process.env.TOKEN_SUFFIX;
  const currentBlock = (await web3.eth.getBlockNumber()) + 100;
  
  const tier1 = [{
    name: 'Warrior',
    symbol: 'A:WARRIOR',
    attack: 50,
    defense: 15,
    troopImprovementFactor: 0,
    initialSupply: 10000,
    tokensPerBlock: 2,
  },
  {
    name: 'Archer',
    symbol: 'A:ARCHER',
    attack: 15,
    defense: 50,
    troopImprovementFactor: 0,
    initialSupply: 10000,
    tokensPerBlock: 2,
  },
  {
    name: 'Grunt',
    symbol: 'A:GRUNT',
    attack: 50,
    defense: 15,
    troopImprovementFactor: 0,
    initialSupply: 10000,
    tokensPerBlock: 2,
  },
  {
    name: 'Archer Grunt',
    symbol: 'A:ORC-ARCHER',
    attack: 15,
    defense: 50,
    troopImprovementFactor: 0,
    initialSupply: 10000,
    tokensPerBlock: 2,
    },
  ];

  const tier2 = [{
      name: 'A:Armored Warrior',
      symbol: 'A:ARMORED-WARRIOR',
      attack: 130,
      defense: 30,
      troopImprovementFactor: 0,
      initialSupply: 1000,
      tokensPerBlock: 1,
    },
    {
      name: 'A:Crossbowman',
      symbol: 'A:CROSSBOWNMAN',
      attack: 30,
      defense: 130,
      troopImprovementFactor: 0,
      initialSupply: 1000,
      tokensPerBlock: 1,
      },
      {
        name: 'A:Pike Orc',
        symbol: 'A:PIKE-ORC',
        attack: 130,
      defense: 30,
      troopImprovementFactor: 0,
        initialSupply: 1000,
        tokensPerBlock: 1,
      },
      {
        name: 'A:Armored Grunt',
        symbol: 'A:ARMORED-GRUNT',
        attack: 30,
        defense: 130,
        troopImprovementFactor: 0,
        initialSupply: 1000,
        tokensPerBlock: 1,
      },
  ];
  
  const tier3 = [{
      name: 'A:Wizard',
      symbol: 'A:WIZARD',
      attack: 150,
      defense: 150,
      troopImprovementFactor: 0,
      initialSupply: 100,
      tokensPerBlock: 0.5,
    },
    {
      name: 'A:Shaman',
      symbol: 'A:SHAMAN',
      attack: 150,
      defense: 150,
      troopImprovementFactor: 0,
      initialSupply: 100,
      tokensPerBlock: 0.5,
    },
  ];

  const publish = async (tier) => {
    for (let i = 0; i < tier.length; i++) {
      const unit = tier[i];
  
      console.log(`Publishing ${unit.name} and minting the initial supply ${unit.initialSupply}`);
      await deployer.deploy(UnitToken, `${unit.name}${suffix}`, `${unit.symbol}${suffix}`, unit.attack, unit.defense, unit.troopImprovementFactor);
      const instance = await UnitToken.deployed();
      await instance.mint(accounts[0], web3.utils.toWei(unit.initialSupply.toString()));

      console.log(`${unit.symbol}${suffix} - ${instance.address}`);
      await deployer.deploy(
        APWarsFarmManagerV2,
        instance.address,
        accounts[0],
        accounts[0],
        web3.utils.toWei(unit.tokensPerBlock.toString()),
        currentBlock);
      
      const farmManagerInstance = await APWarsFarmManagerV2.deployed();
      console.log(`${unit.symbol}${suffix} farm manager - ${farmManagerInstance.address}`);

      console.log('Transfering ownership to farm manager');
      await instance.transferOwnership(farmManagerInstance.address);
    }
  };

  await publish(tier1);
  await publish(tier2);
  await publish(tier3);
};
