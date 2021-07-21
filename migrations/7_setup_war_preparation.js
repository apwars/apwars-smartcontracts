const APWarsCombinator = artifacts.require("APWarsCombinator");
const APWarsCombinatorManager = artifacts.require("APWarsCombinatorManager");

module.exports = async (deployer, network, accounts) => {

  const setup = {
    feeAddress: "0xf6375FfD609Fa886803C27260d872CcCfA7d9257",
    wGOLD: '0x3A5c025065a14EF9e834fBD90aeD3876a07c60EA',
    burnManager: '0x1a6E3a930be1Ff2fE959FBFc365dAf8045280eAd',
    collectibles: '0x3fdE3A5FbC76b4AaB5955ed091DfcE2f84fA3Fb0',
    units: {
      wWARRIOR: '0x0447072Aa3E3b448d77cD9B322cDfe7Ea990A1F8',
      wARCHER: '0x159FF39cf0fFca109b123dc81890Cf37D157eBE7',
      // wARMOUREDWARRIOR: '0x84866c7C2c490242ae37C9d73de588203B93e0B2',
      // wCROSSBOWMAN: '0x9DB33bFDBCE63aC62717950ACea4cf030BDCFD92',
      // wWIZARD: '0x4F1580e353c16F05f234D2718Dd12d3f7B44a21d',
      // wHORSEMAN: '0x022465BCd48f6eE55236a555E0Da21c960c2d8EA',
      // wGRUNT: '0x9FA4946089CBE11a5Bfda9C397e29cd093626F37',
      // wORCARCHER: '0x3Bd57F3209a88016f7645bbD6FacacAf50d631d4',
      // wPIKEORC: '0x7b58Fc38F4EcD3f14F0189307881E63d79490A07',
      // wARMOUREDGRUNT: '0xC2d75018Cd8c2e87794d5839B80c35a09EeeA1BB',
      // wSHAMAN: '0x433499f0c12E6aE0D1f2A90fB640AE1EBe1Df890',
      // wSKELETONWARRIOR: '0x7a355C7633d3d097F6ed009faC66727E7C4E0Dee',
      // wHOUND: '0x7DC031d20cc8DB621A9aaD99D834CfBCF1DCA8bf',
      // wUNDEADARCHER: '0x2d533A617956f47E63150A0fb13441Da202DAC9F',
      // wUNDEADPIKEMAN: '0x8df7145Fc3a1B7BC590a229737d8c39bD058Ab49',
      // wWITCH: '0xB80797707aa7b6663d87cc4Cd754DC0F206c6eB3',
      // wDEATHKNIGHT: '0xaF583Ff10E58f2FD3dc00E831eEF1db1A4B1D65f',
      // wWARG: '0x9a1E2a31A6a7BF8d8daCA7C6e2b7Ba3b16F2A554'
    },
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
    const unitAddress = setup.units[unit];
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
      unitAddress,
      web3.utils.toWei('1000', 'ether'),
      0,
      0
    );
    await combinatorManager.setupGameItemC(
      idCombinator,
      setup.collectibles,
      10,
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
