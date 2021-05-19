const War = artifacts.require('APWarsWarMachine');
const Collectibles = artifacts.require('APWarsCollectibles');
const BurnManager = artifacts.require('APWarsBurnManagerV2');
const UnitToken = artifacts.require('APWarsUnitToken');

contract('WarMachine', accounts => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let teamAArcher = null;
  let teamAWarrior = null;
  let teamACavalry = null;
  let teamANoble = null;
  let teamBArcher = null;
  let teamBWarior = null;
  let teamBCavalry = null;
  let teamBNoble = null;
  let gold = null;
  let instance = null;

  it('should create unit tokens and define teams', async () => {
    instance = await War.new();

    gold = await UnitToken.new('Gold', 'A:GOLD', 0, 0, 0);

    teamAArcher = await UnitToken.new('Team A Archer', 'A:ARCHER', 15, 50, 0);
    teamAWarrior = await UnitToken.new('Team A Warrior', 'A:WARRIOR', 50, 15, 0);
    teamACavalry = await UnitToken.new('Team A Cavalry', 'A:CAVALRY', 130, 30, 0);
    teamANoble = await UnitToken.new('Team A Noble', 'A:NOBLE', 100, 50, 10);

    teamBArcher = await UnitToken.new('Team B Archer', 'A:ARCHER', 15, 50, 0);
    teamBWarior = await UnitToken.new('Team B Warrior', 'A:WARRIOR', 50, 15, 0);
    teamBCavalry = await UnitToken.new('Team B Cavalry', 'A:CAVALRY', 130, 30, 0);
    teamBNoble = await UnitToken.new('Team B Noble', 'A:NOBLE', 100, 50, 10);

    //minting for test

    await Promise.all(
      [
        gold,
        teamAArcher,
        teamAWarrior,
        teamACavalry,
        teamANoble,
        teamBArcher,
        teamBWarior,
        teamBCavalry,
        teamBNoble
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );
  });

  it('should distribute teams', async () => {
    teamAArcher.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamAArcher.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamAArcher.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamAWarrior.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamAWarrior.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamAWarrior.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamACavalry.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamACavalry.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamACavalry.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamANoble.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.001).toString(), 'ether'));
    teamANoble.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.002).toString(), 'ether'));
    teamANoble.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.005).toString(), 'ether'));

    teamBArcher.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamBArcher.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamBArcher.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamBWarior.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamBWarior.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamBWarior.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamBCavalry.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamBCavalry.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamBCavalry.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamBNoble.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.001).toString(), 'ether'));
    teamBNoble.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.002).toString(), 'ether'));
    teamBNoble.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.005).toString(), 'ether'));
  });

  it('should allow war contract to run transferFrom', async () => {
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[1]), { from: accounts[1] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[2]), { from: accounts[2] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[3]), { from: accounts[3] });

    teamAWarrior.approve(instance.address, await teamAWarrior.balanceOf(accounts[1]), { from: accounts[1] });
    teamAWarrior.approve(instance.address, await teamAWarrior.balanceOf(accounts[2]), { from: accounts[2] });
    teamAWarrior.approve(instance.address, await teamAWarrior.balanceOf(accounts[3]), { from: accounts[3] });

    teamACavalry.approve(instance.address, await teamACavalry.balanceOf(accounts[1]), { from: accounts[1] });
    teamACavalry.approve(instance.address, await teamACavalry.balanceOf(accounts[2]), { from: accounts[2] });
    teamACavalry.approve(instance.address, await teamACavalry.balanceOf(accounts[3]), { from: accounts[3] });

    teamANoble.approve(instance.address, await teamANoble.balanceOf(accounts[1]), { from: accounts[1] });
    teamANoble.approve(instance.address, await teamANoble.balanceOf(accounts[2]), { from: accounts[2] });
    teamANoble.approve(instance.address, await teamANoble.balanceOf(accounts[3]), { from: accounts[3] });


    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[4]), { from: accounts[4] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[5]), { from: accounts[5] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[6]), { from: accounts[6] });

    teamBWarior.approve(instance.address, await teamBWarior.balanceOf(accounts[4]), { from: accounts[4] });
    teamBWarior.approve(instance.address, await teamBWarior.balanceOf(accounts[5]), { from: accounts[5] });
    teamBWarior.approve(instance.address, await teamBWarior.balanceOf(accounts[6]), { from: accounts[6] });

    teamBCavalry.approve(instance.address, await teamBCavalry.balanceOf(accounts[4]), { from: accounts[4] });
    teamBCavalry.approve(instance.address, await teamBCavalry.balanceOf(accounts[5]), { from: accounts[5] });
    teamBCavalry.approve(instance.address, await teamBCavalry.balanceOf(accounts[6]), { from: accounts[6] });

    teamBNoble.approve(instance.address, await teamBNoble.balanceOf(accounts[4]), { from: accounts[4] });
    teamBNoble.approve(instance.address, await teamBNoble.balanceOf(accounts[5]), { from: accounts[5] });
    teamBNoble.approve(instance.address, await teamBNoble.balanceOf(accounts[6]), { from: accounts[6] });
  });

  it('should deposit units in the war contract', async () => {
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);

    await instance.createWar('War#1', externalRandomSourceHash);

    await instance.setup(
      gold.address,
      burnManager.address,
      [teamAArcher.address, teamAWarrior.address, teamACavalry.address, teamANoble.address],
      [teamBArcher.address, teamBWarior.address, teamBCavalry.address, teamBNoble.address],
      collectibles.address,
      [0, 0, 0, 0, 0],
    );

    const depositAndCheck = async (accList, unit) => {
      for (i = 0; i < accList.length; i++) {
        const acc = accList[i];
        const account = accounts[acc];

        const balanceOf = (await unit.balanceOf(account)).toString();
        await instance.deposit(unit.address, balanceOf, { from:  account});

        expect((await instance.getPlayerInfo([unit.address], account)).depositAmount.toString()).to.be.equal(balanceOf, `#${i} fail to check ${account}`);
        expect((await unit.balanceOf(account)).toString()).to.be.equal('0', `#${i} fail to check balanceOf ${account}`);
      }
    }

    await depositAndCheck([1, 2, 3], teamAArcher);
    await depositAndCheck([1, 2, 3], teamAWarrior);
    await depositAndCheck([1, 2, 3], teamACavalry);
    await depositAndCheck([1, 2, 3], teamANoble);

    await depositAndCheck([4, 5, 6], teamBArcher);
    await depositAndCheck([4, 5, 6], teamBWarior);
    await depositAndCheck([4, 5, 6], teamBCavalry);
    await depositAndCheck([4, 5, 6], teamBNoble);
  });

  it('should finish war', async () => {
    await instance.finishFirstRound(externalRandomSource);
    await instance.finishSecondRound(externalRandomSource);

    const war = await instance.war();
    const teamAInfo = await instance.getWarInfo(1, []);
    const teamBInfo = await instance.getWarInfo(2, []);
    const attackPowerTeamA = teamAInfo.totalAttackPower;
    const attackPowerTeamB = teamAInfo.totalAttackPower;
    const defensePowerTeamA = teamBInfo.totalDefensePower;
    const defensePowerTeamB = teamBInfo.totalDefensePower;

    console.log({
      attackPowerTeamA: attackPowerTeamA.toString(),
      attackPowerTeamB: attackPowerTeamB.toString(),
      defensePowerTeamA: defensePowerTeamA.toString(),
      defensePowerTeamB: defensePowerTeamB.toString(),
    });

    await instance.withdraw(teamAArcher.address, {from: accounts[1]});
    
    console.log('name', war.name);
    console.log('attackerTeam', war.attackerTeam.toString());
    console.log('defenderTeam', war.defenderTeam.toString());
    console.log('winner', war.winner.toString());
    console.log('attackerLuck', war.attackerLuck.toString());
    console.log('isBadLuck', war.isBadLuck);
    console.log('attackerCasualty', war.attackerCasualty.toString());
    console.log('defenderCasualty', war.defenderCasualty.toString());
    console.log('-------');
    console.log('finalAttackPower', war.finalAttackPower.toString());
    console.log('finalDefensePower', war.finalDefensePower.toString());
    console.log('-------');
    console.log('percAttackerLosses', war.percAttackerLosses.toString());
    console.log('percDefenderLosses', war.percDefenderLosses.toString());
  });
});

contract('A war with just one side (A)', accounts => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let teamAArcher = null;
  let teamAWarrior = null;
  let teamACavalry = null;
  let teamANoble = null;
  let teamBArcher = null;
  let teamBWarior = null;
  let teamBCavalry = null;
  let teamBNoble = null;
  let gold = null;
  let instance = null;

  it('should create unit tokens and define teams', async () => {
    instance = await War.new();

    gold = await UnitToken.new('Gold', 'A:GOLD', 0, 0, 0);

    teamAArcher = await UnitToken.new('Team A Archer', 'A:ARCHER', 15, 50, 0);
    teamBArcher = await UnitToken.new('Team B Archer', 'A:ARCHER', 15, 50, 0);

    await Promise.all(
      [
        gold,
        teamAArcher,
        teamBArcher
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );
  });

  it('should distribute teams', async () => {
    teamAArcher.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamAArcher.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamAArcher.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamBArcher.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamBArcher.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamBArcher.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));
});

  it('should allow war contract to run transferFrom', async () => {
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[1]), { from: accounts[1] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[2]), { from: accounts[2] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[3]), { from: accounts[3] });

    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[4]), { from: accounts[4] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[5]), { from: accounts[5] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[6]), { from: accounts[6] });
  });

  it('should deposit units in the war contract', async () => {
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);

    await instance.createWar('War#1', externalRandomSourceHash);

    await gold.transfer(instance.address, await gold.balanceOf(accounts[0]));
    
    await instance.setup(
      gold.address,
      burnManager.address,
      [teamAArcher.address],
      [teamAArcher.address],
      collectibles.address,
      [0, 0, 0, 0, 0]
    );

    const depositAndCheck = async (accList, unit) => {
      for (i = 0; i < accList.length; i++) {
        const acc = accList[i];
        const account = accounts[acc];

        const balanceOf = (await unit.balanceOf(account)).toString();
        await instance.deposit(unit.address, balanceOf, { from:  account});

        expect((await instance.getPlayerInfo([unit.address], account)).depositAmount.toString()).to.be.equal(balanceOf, `#${i} fail to check ${account}`);
        expect((await unit.balanceOf(account)).toString()).to.be.equal('0', `#${i} fail to check balanceOf ${account}`);
      }
    }

    await depositAndCheck([1, 2, 3], teamAArcher);
  });

  it('should finish war', async () => {
    await instance.finishFirstRound(externalRandomSource);
    await instance.finishSecondRound(externalRandomSource);

    const war = await instance.war();
    const teamAInfo = await instance.getWarInfo(1, []);
    const teamBInfo = await instance.getWarInfo(2, []);
    const attackPowerTeamA = teamAInfo.totalAttackPower;
    const attackPowerTeamB = teamAInfo.totalAttackPower;
    const defensePowerTeamA = teamBInfo.totalDefensePower;
    const defensePowerTeamB = teamBInfo.totalDefensePower;

    console.log({
      attackPowerTeamA: attackPowerTeamA.toString(),
      attackPowerTeamB: attackPowerTeamB.toString(),
      defensePowerTeamA: defensePowerTeamA.toString(),
      defensePowerTeamB: defensePowerTeamB.toString(),
    });

    await instance.withdraw(teamAArcher.address, {from: accounts[1]});
    
    console.log('name', war.name);
    console.log('attackerTeam', war.attackerTeam.toString());
    console.log('defenderTeam', war.defenderTeam.toString());
    console.log('winner', war.winner.toString());
    console.log('attackerLuck', war.attackerLuck.toString());
    console.log('isBadLuck', war.isBadLuck);
    console.log('attackerCasualty', war.attackerCasualty.toString());
    console.log('defenderCasualty', war.defenderCasualty.toString());
    console.log('-------');
    console.log('finalAttackPower', war.finalAttackPower.toString());
    console.log('finalDefensePower', war.finalDefensePower.toString());
    console.log('-------');
    console.log('percAttackerLosses', war.percAttackerLosses.toString());
    console.log('percDefenderLosses', war.percDefenderLosses.toString());
  });
});

contract('A war with just one side (B)', accounts => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let teamAArcher = null;
  let teamAWarrior = null;
  let teamACavalry = null;
  let teamANoble = null;
  let teamBArcher = null;
  let teamBWarior = null;
  let teamBCavalry = null;
  let teamBNoble = null;
  let gold = null;
  let instance = null;

  it('should create unit tokens and define teams', async () => {
    instance = await War.new();

    gold = await UnitToken.new('Gold', 'A:GOLD', 0, 0, 0);

    teamAArcher = await UnitToken.new('Team A Archer', 'A:ARCHER', 15, 50, 0);

    teamBArcher = await UnitToken.new('Team B Archer', 'A:ARCHER', 15, 50, 0);

    await Promise.all(
      [
        gold,
        teamAArcher,
        teamBArcher
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );

  });

  it('should distribute teams', async () => {
    teamAArcher.transfer(accounts[1], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamAArcher.transfer(accounts[2], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamAArcher.transfer(accounts[3], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));

    teamBArcher.transfer(accounts[4], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.3).toString(), 'ether'));
    teamBArcher.transfer(accounts[5], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.2).toString(), 'ether'));
    teamBArcher.transfer(accounts[6], web3.utils.toWei((UNIT_DEFAULT_SUPPLY * 0.5).toString(), 'ether'));
  });

  it('should allow war contract to run transferFrom', async () => {
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[1]), { from: accounts[1] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[2]), { from: accounts[2] });
    teamAArcher.approve(instance.address, await teamAArcher.balanceOf(accounts[3]), { from: accounts[3] });

    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[4]), { from: accounts[4] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[5]), { from: accounts[5] });
    teamBArcher.approve(instance.address, await teamBArcher.balanceOf(accounts[6]), { from: accounts[6] });
  });

  it('should deposit units in the war contract', async () => {
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);

    await instance.createWar('War#1', externalRandomSourceHash);

    await gold.transfer(instance.address, await gold.balanceOf(accounts[0]));
    
    await instance.setup(
      gold.address,
      burnManager.address,
      [teamAArcher.address],
      [teamAArcher.address],
      collectibles.address,
      [0, 0, 0, 0, 0],
    );

    const depositAndCheck = async (accList, unit) => {
      for (i = 0; i < accList.length; i++) {
        const acc = accList[i];
        const account = accounts[acc];

        const balanceOf = (await unit.balanceOf(account)).toString();
        await instance.deposit(unit.address, balanceOf, { from:  account});

        expect((await instance.getPlayerInfo([unit.address], account)).depositAmount.toString()).to.be.equal(balanceOf, `#${i} fail to check ${account}`);
        expect((await unit.balanceOf(account)).toString()).to.be.equal('0', `#${i} fail to check balanceOf ${account}`);
      }
    }

    //await depositAndCheck([1, 2, 3], teamAArcher);
    await depositAndCheck([4, 5, 6], teamBArcher);
  });

  it('should finish war', async () => {
    await instance.finishFirstRound(externalRandomSource);
    await instance.finishSecondRound(externalRandomSource);

    const war = await instance.war();
    const teamAInfo = await instance.getWarInfo(1, []);
    const teamBInfo = await instance.getWarInfo(2, []);
    const attackPowerTeamA = teamAInfo.totalAttackPower;
    const attackPowerTeamB = teamAInfo.totalAttackPower;
    const defensePowerTeamA = teamBInfo.totalDefensePower;
    const defensePowerTeamB = teamBInfo.totalDefensePower;

    console.log({
      attackPowerTeamA: attackPowerTeamA.toString(),
      attackPowerTeamB: attackPowerTeamB.toString(),
      defensePowerTeamA: defensePowerTeamA.toString(),
      defensePowerTeamB: defensePowerTeamB.toString(),
    });

    await instance.withdraw(teamAArcher.address, {from: accounts[4]});
    
    console.log('name', war.name);
    console.log('attackerTeam', war.attackerTeam.toString());
    console.log('defenderTeam', war.defenderTeam.toString());
    console.log('winner', war.winner.toString());
    console.log('attackerLuck', war.attackerLuck.toString());
    console.log('isBadLuck', war.isBadLuck);
    console.log('attackerCasualty', war.attackerCasualty.toString());
    console.log('defenderCasualty', war.defenderCasualty.toString());
    console.log('-------');
    console.log('finalAttackPower', war.finalAttackPower.toString());
    console.log('finalDefensePower', war.finalDefensePower.toString());
    console.log('-------');
    console.log('percAttackerLosses', war.percAttackerLosses.toString());
    console.log('percDefenderLosses', war.percDefenderLosses.toString());
  });
});

contract('Simple War (without nfts)', accounts => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let gold = null;
  let teamA = null;
  let teamB = null;

  it('should prepare war', async () => {
    const instance = await War.new();
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");

    gold = await UnitToken.new('Gold', 'A:GOLD', 0, 0, 0);
    teamA = await UnitToken.new('Team A Archer', 'A:ARCHER', 15, 50, 0);
    teamB = await UnitToken.new('Team B Archer', 'A:ARCHER', 15, 50, 0);

    await Promise.all(
      [
        gold,
        teamA,
        teamB
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );

    const totalSupply = web3.utils.toWei(UNIT_DEFAULT_SUPPLY.toString());
    await gold.transfer(instance.address, totalSupply);

    await teamA.transfer(accounts[1], totalSupply);
    await teamA.approve(instance.address, totalSupply, { from: accounts[1] });
    await teamB.transfer(accounts[2], totalSupply);
    await teamB.approve(instance.address, totalSupply, { from: accounts[2] });

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);
    await instance.createWar('War#1', externalRandomSourceHash);

    await instance.setup(
      gold.address,
      burnManager.address,
      [teamA.address],
      [teamB.address],
      collectibles.address,
      [0, 0, 0, 0, 0],
    );
    
    await instance.deposit(teamA.address, totalSupply, { from: accounts[1] });
    await instance.deposit(teamB.address, totalSupply, { from: accounts[2] });

    await instance.finishFirstRound(externalRandomSource);
    await instance.finishSecondRound(externalRandomSource);

    const war = await instance.war();
    const winnerAccount = accounts[war.winner];
    
    const totalPrize = await instance.getTotalPrize();
    let goldContractBalance = await gold.balanceOf(instance.address);

    expect(totalPrize.toString()).to.be.equal(goldContractBalance.toString(), 'Fail to check contract balance vs total prize');
    
    await instance.withdrawPrize({ from: winnerAccount });

    goldContractBalance = await gold.balanceOf(instance.address);
    expect(goldContractBalance.toString()).to.be.equal('0', 'Fail to check contract balance after withdraw');


    await instance.withdraw(teamA.address, { from: accounts[1] });
    
    let teamABalance = await teamA.balanceOf(instance.address);
    let teamBBalance = await teamB.balanceOf(instance.address);

    expect(teamABalance.toString()).to.be.equal('0', 'Fail to check team A contract balance after user withdrawal');
    expect(teamBBalance.toString()).to.be.equal(totalSupply, 'Fail to check team B contract balance after user withdrawal');
  });
});

contract('Simple War (with nfts)', accounts => {
  const externalRandomSource = '0x019f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
  const UNIT_DEFAULT_SUPPLY = 10000000;
  const MULT = 10 ** 18;

  let gold = null;
  let teamA = null;
  let teamB = null;

  it('should prepare war', async () => {
    const instance = await War.new();
    const burnManager = await BurnManager.new(accounts[0]);
    const collectibles = await Collectibles.new(burnManager.address, "");

    gold = await UnitToken.new('Gold', 'A:GOLD', 0, 0, 0);
    teamA = await UnitToken.new('Team A Archer', 'A:ARCHER', 15, 50, 0);
    teamB = await UnitToken.new('Team B Archer', 'A:ARCHER', 15, 50, 0);

    collectibles.mint(accounts[1], 1, 1, '0x0');
    collectibles.mint(accounts[1], 2, 1, '0x0');
    collectibles.mint(accounts[2], 3, 1, '0x0');
    collectibles.mint(accounts[2], 4, 1, '0x0');

    await Promise.all(
      [
        gold,
        teamA,
        teamB
      ].map(token => token.mint(accounts[0], web3.utils.toWei((UNIT_DEFAULT_SUPPLY).toString())))
    );

    const totalSupply = web3.utils.toWei(UNIT_DEFAULT_SUPPLY.toString());
    await gold.transfer(instance.address, totalSupply);

    await teamA.transfer(accounts[1], totalSupply);
    await teamA.approve(instance.address, totalSupply, { from: accounts[1] });
    await teamB.transfer(accounts[2], totalSupply);
    await teamB.approve(instance.address, totalSupply, { from: accounts[2] });

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);
    await instance.createWar('War#1', externalRandomSourceHash);
      
    await instance.setup(
      gold.address,
      burnManager.address,
      [teamA.address],
      [teamB.address],
      collectibles.address,
      [1, 2, 3, 0, 4],
    );
    
    await instance.deposit(teamA.address, totalSupply, { from: accounts[1] });
    await instance.deposit(teamB.address, totalSupply, { from: accounts[2] });


    await instance.finishFirstRound(externalRandomSource);
    await instance.finishSecondRound(externalRandomSource);
    const war = await instance.war();
    const winnerAccount = accounts[war.winner];
    
    const totalPrize = await instance.getTotalPrize();
    let goldContractBalance = await gold.balanceOf(instance.address);

    expect(totalPrize.toString()).to.be.equal(goldContractBalance.toString(), 'Fail to check contract balance vs total prize');
    
    await instance.withdrawPrize({ from: winnerAccount });

    goldContractBalance = await gold.balanceOf(instance.address);
    expect(goldContractBalance.toString()).to.be.equal('0', 'Fail to check contract balance after withdraw');


    await instance.withdraw(teamA.address, { from: accounts[1] });
    await instance.withdraw(teamB.address, { from: accounts[2] });
    
    let teamABalance = await teamA.balanceOf(instance.address);
    let teamBBalance = await teamB.balanceOf(instance.address);

    expect(teamABalance.toString()).to.be.equal('0', 'Fail to check team A contract balance after user withdrawal');
    expect(teamBBalance.toString()).to.be.equal('0', 'Fail to check team B contract balance after user withdrawal');

    const player1 = await instance.getPlayerAddress(0);
    const player2 = await instance.getPlayerAddress(1);

    expect(player1).to.be.equal(accounts[1]);
    expect(player2).to.be.equal(accounts[2]);
  });
});