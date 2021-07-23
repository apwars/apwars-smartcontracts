const APWarsCombinator = artifacts.require("APWarsCombinator");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");

module.exports = async (deployer, network, accounts) => {

  const setup = {
    feeAddress: "0xf6375FfD609Fa886803C27260d872CcCfA7d9257",
    wGOLD: '0x3A5c025065a14EF9e834fBD90aeD3876a07c60EA',
    burnManager: '0x54420d5cd4b5d4478438c0e810dd9d03582037d0',
    collectibles: '0x3fdE3A5FbC76b4AaB5955ed091DfcE2f84fA3Fb0',
    units: [
      {
        name: 'wWARRIOR',
        contract: '0x0447072Aa3E3b448d77cD9B322cDfe7Ea990A1F8',
        idCollectibles: 28
      },
      {
        name: 'wARCHER',
        contract: '0x159FF39cf0fFca109b123dc81890Cf37D157eBE7',
        idCollectibles: 28
      },
      {
        name: 'wGRUNT',
        contract: '0x9FA4946089CBE11a5Bfda9C397e29cd093626F37',
        idCollectibles: 28
      },
      {
        name: 'wORCARCHER',
        contract: '0x3Bd57F3209a88016f7645bbD6FacacAf50d631d4',
        idCollectibles: 28
      },
      {
        name: 'wSKELETONWARRIOR',
        contract: '0x7a355C7633d3d097F6ed009faC66727E7C4E0Dee',
        idCollectibles: 28
      },
      {
        name: 'wHOUND',
        contract: '0x7DC031d20cc8DB621A9aaD99D834CfBCF1DCA8bf',
        idCollectibles: 28
      },
      {
        name: 'wARMOUREDWARRIOR',
        contract: '0x84866c7C2c490242ae37C9d73de588203B93e0B2',
        idCollectibles: 29
      },
      {
        name: 'wCROSSBOWMAN',
        contract: '0x9DB33bFDBCE63aC62717950ACea4cf030BDCFD92',
        idCollectibles: 29
      },
      {
        name: 'wPIKEORC',
        contract: '0x7b58Fc38F4EcD3f14F0189307881E63d79490A07',
        idCollectibles: 29
      },
      {
        name: 'wARMOUREDGRUNT',
        contract: '0xC2d75018Cd8c2e87794d5839B80c35a09EeeA1BB',
        idCollectibles: 29
      },
      {
        name: 'wUNDEADARCHER',
        contract: '0x2d533A617956f47E63150A0fb13441Da202DAC9F',
        idCollectibles: 29
      },
      {
        name: 'wUNDEADPIKEMAN',
        contract: '0x8df7145Fc3a1B7BC590a229737d8c39bD058Ab49',
        idCollectibles: 29
      },
      {
        name: 'wWIZARD',
        contract: '0x4F1580e353c16F05f234D2718Dd12d3f7B44a21d',
        idCollectibles: 30
      },
      {
        name: 'wSHAMAN',
        contract: '0x433499f0c12E6aE0D1f2A90fB640AE1EBe1Df890',
        idCollectibles: 30
      },
      {
        name: 'wWITCH',
        contract: '0xB80797707aa7b6663d87cc4Cd754DC0F206c6eB3',
        idCollectibles: 30
      }
    ]
  }
  await deployer.deploy(APWarsCombinator);
  const combinator = await APWarsCombinator.deployed();
  await deployer.deploy(APWarsCombinatorManager);
  const combinatorManager = await APWarsCombinatorManager.deployed();
  await combinator.setup(setup.feeAddress, setup.burnManager, combinatorManager.address);

  let idCombinator = 0;
  const timeBlock = 15;
  const maxMultiple = 1;
  const isEnabled = true;
  let printsUnits = [];

  for (let unit in setup.units) {
    const unitInfo = setup.units[unit];
    idCombinator++;
    printsUnits.push({ unit: unit, idCombinator: idCombinator });
    await combinatorManager.setupCombinator(idCombinator, timeBlock, maxMultiple, isEnabled);
    await combinatorManager.setupTokenA(
      idCombinator,
      setup.wGOLD,
      web3.utils.toWei('100', 'ether'),
      0,
      0,
    );
    await combinatorManager.setupTokenB(
      idCombinator,
      unitInfo.contract,
      web3.utils.toWei('1000', 'ether'),
      0,
      0
    );
    await combinatorManager.setupGameItemC(
      idCombinator,
      setup.collectibles,
      unitInfo.idCollectibles,
      1
    );
  }

  console.log(`Combinator: ${combinator.address}`);
  console.log(`CombinatorManager: ${combinatorManager.address}`);
  console.log("");
  printsUnits.map(print => {
    console.log(`Unit: ${print.unit}`);
    console.log(`idCombinator: ${print.idCombinator} \n`);
  });

};
