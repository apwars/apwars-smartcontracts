const APWarsWarMachineV2 = artifacts.require("APWarsWarMachineV2");

module.exports = async (deployer, network, accounts) => {

  await deployer.deploy(APWarsWarMachineV2);
  const warMachine = await APWarsWarMachineV2.new();
  const externalRandomSource = '0x451de2aaf1d2e9ecaa1a3ca228d0976fc561cfe5e971774b4ada47624def15b6';
  const externalRandomSourceHash = await warMachine.hashExternalRandomSource(externalRandomSource);

  // const setupTest = {
  //   wGOLD: '0x3A5c025065a14EF9e834fBD90aeD3876a07c60EA',
  //   burnManager: '0x1a6E3a930be1Ff2fE959FBFc365dAf8045280eAd',
  //   teamA: {
  //     wWARRIOR: '0x0447072Aa3E3b448d77cD9B322cDfe7Ea990A1F8',
  //     wARCHER: '0x159FF39cf0fFca109b123dc81890Cf37D157eBE7',
  //     wARMOUREDWARRIOR: '0x84866c7C2c490242ae37C9d73de588203B93e0B2',
  //     wCROSSBOWMAN: '0x9DB33bFDBCE63aC62717950ACea4cf030BDCFD92',
  //     wWIZARD: '0x4F1580e353c16F05f234D2718Dd12d3f7B44a21d',
  //     wHORSEMAN: '0x022465BCd48f6eE55236a555E0Da21c960c2d8EA',
  //   },
  //   teamB: {
  //     wGRUNT: '0x9FA4946089CBE11a5Bfda9C397e29cd093626F37',
  //     wORCARCHER: '0x3Bd57F3209a88016f7645bbD6FacacAf50d631d4',
  //     wPIKEORC: '0x7b58Fc38F4EcD3f14F0189307881E63d79490A07',
  //     wARMOUREDGRUNT: '0xC2d75018Cd8c2e87794d5839B80c35a09EeeA1BB',
  //     wSHAMAN: '0x433499f0c12E6aE0D1f2A90fB640AE1EBe1Df890',
  //     wSKELETONWARRIOR: '0x7a355C7633d3d097F6ed009faC66727E7C4E0Dee',
  //     wHOUND: '0x7DC031d20cc8DB621A9aaD99D834CfBCF1DCA8bf',
  //     wUNDEADARCHER: '0x2d533A617956f47E63150A0fb13441Da202DAC9F',
  //     wUNDEADPIKEMAN: '0x8df7145Fc3a1B7BC590a229737d8c39bD058Ab49',
  //     wWITCH: '0xB80797707aa7b6663d87cc4Cd754DC0F206c6eB3',
  //     wDEATHKNIGHT: '0xaF583Ff10E58f2FD3dc00E831eEF1db1A4B1D65f',
  //     wWARG: '0x9a1E2a31A6a7BF8d8daCA7C6e2b7Ba3b16F2A554'
  //   },
  //   collectibles: '0x3fdE3A5FbC76b4AaB5955ed091DfcE2f84fA3Fb0',
  //   collectiblesNFTs: [2, 3, 4, 5, 6],
  // }

  const setup = {
    wGOLD: '0x7Ab6eedd9443e0e98E5Ea93667CA5B250b8ddA51',
    burnManager: '0xBeC25BD8b102761ab70bd821181A4F679C6EdC58',
    teamA: {
      wWARRIOR: '0x54f653f539a78d3db0e0d3b166cf32c4f6cc5fb6',
      wARCHER: '0xAA2E03E7838148ce9FAd6Ce4C00275D89127A03e',
      wARMOUREDWARRIOR: '0xd67761dF2b76eE251d48816691f5ff7728d94DAa',
      wCROSSBOWMAN: '0xA0ecF9c7114eFFB43440B95D54e09A2a67331236',
      wWIZARD: '0x1225C7999483544c7859fE5A23c9Be70d14d5378',
    },
    teamB: {
      wGRUNT: '0xd7544Fe7668f3dfb7AD21F9E02D7A51e116b6D75',
      wORCARCHER: '0x934e11a44b2e817fe9bd6f337ef21bd35e46080e',
      wPIKEORC: '0x491c739efd076655f7D8D0DB545b7fb09DdF517f',
      wARMOUREDGRUNT: '0x56c09E954690d80C5728194f7eAf473737Dc2180',
      wSHAMAN: '0x10eAAC888b70aBE542a50b787ABe7f94b8989CB7',
      wSKELETONWARRIOR: '0xb5d488dc4DE64A6a968D8f317DB8DE2cDBF52828',
      wHOUND: '0x4D21177Bf8a0F9cfAca6d0f568Ff3e79a121B106',
      wUNDEADARCHER: '0xd048cDf2e870E60D46527463a14aEFC0377D754c',
      wUNDEADPIKEMAN: '0x8b394cfAeBA9812801C92388570C95208Ad1300D',
      wWITCH: '0x2a63DDDD2c0ba10F465080a06563aF3acb5d1d3c',
    },
    collectibles: '0x79ab3a6f3f1627535a8774fd2feed322d58f2d02',
    collectiblesNFTs: [2, 3, 4, 5, 6],
  }

  await warMachine.setup(
    setup.wGOLD,
    setup.burnManager,
    [
      setup.teamA.wWARRIOR,
      setup.teamA.wARCHER,
      setup.teamA.wARMOUREDWARRIOR,
      setup.teamA.wCROSSBOWMAN,
      setup.teamA.wWIZARD,
    ],
    [
      setup.teamB.wGRUNT,
      setup.teamB.wORCARCHER,
      setup.teamB.wPIKEORC,
      setup.teamB.wARMOUREDGRUNT,
      setup.teamB.wSHAMAN,
      setup.teamB.wSKELETONWARRIOR,
      setup.teamB.wHOUND,
      setup.teamB.wUNDEADARCHER,
      setup.teamB.wUNDEADPIKEMAN,
      setup.teamB.wWITCH,
    ],
    setup.collectibles,
    setup.collectiblesNFTs
  );

  await warMachine.createWar('War#2', externalRandomSourceHash);

  console.log('WarMachine:', warMachine.address);
  console.log('externalRandomSource:', externalRandomSource);
  console.log('externalRandomSourceHash:', externalRandomSourceHash);
};


