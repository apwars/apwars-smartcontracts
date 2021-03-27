const War = artifacts.require('War');
const UnitERC20Token = artifacts.require('UnitERC20Token');

contract('War', accounts => {
  const externalRandomSource = '0x009f7d857c47a36ffce885e3978b815ae7b7b5b6f52fff6dae164a3845ad7eff';
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

  it('should create unit tokens and define teams', async () => {
    const instance = await War.deployed();

    teamAArcher = await UnitERC20Token.new('Team A Archer', 'A:ARCHER', 15, 50, 0);
    teamAWarrior = await UnitERC20Token.new('Team A Warrior', 'A:WARRIOR', 50, 15, 0);
    teamACavalry = await UnitERC20Token.new('Team A Cavalry', 'A:CAVALRY', 130, 30, 0);
    teamANoble = await UnitERC20Token.new('Team A Noble', 'A:NOBLE', 100, 50, 10);

    teamBArcher = await UnitERC20Token.new('Team B Archer', 'A:ARCHER', 15, 50, 0);
    teamBWarior = await UnitERC20Token.new('Team B Warrior', 'A:WARRIOR', 50, 15, 0);
    teamBCavalry = await UnitERC20Token.new('Team B Cavalry', 'A:CAVALRY', 130, 30, 0);
    teamBNoble = await UnitERC20Token.new('Team B Noble', 'A:NOBLE', 100, 50, 10);

    //minting for test

    await Promise.all(
      [
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
    const instance = await War.deployed();

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
    const instance = await War.deployed();

    const externalRandomSourceHash = await instance.hashExternalRandomSource(externalRandomSource);

    await instance.createWar('War#1', externalRandomSourceHash);
    
    instance.defineTokenTeam(0, teamAArcher.address, 1);
    instance.defineTokenTeam(0, teamAWarrior.address, 1);
    instance.defineTokenTeam(0, teamACavalry.address, 1);
    instance.defineTokenTeam(0, teamANoble.address, 1);

    instance.defineTokenTeam(0, teamBArcher.address, 2);
    instance.defineTokenTeam(0, teamBWarior.address, 2);
    instance.defineTokenTeam(0, teamBCavalry.address, 2);
    instance.defineTokenTeam(0, teamBNoble.address, 2);

    const depositAndCheck = async (accList, unit) => {
      for (i = 0; i < accList.length; i++) {
        const acc = accList[i];
        const account = accounts[acc];

        const balanceOf = (await unit.balanceOf(account)).toString();
        await instance.deposit(unit.address, balanceOf, { from:  account});

        expect((await instance.getPlayerDeposit(0, unit.address, account)).toString()).to.be.equal(balanceOf, `#${i} fail to check ${account}`);
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
    const instance = await War.deployed();

    await instance.finishFirstRound(0, externalRandomSource);

    const war = await instance.wars(0);
    const attackPowerTeamA = await instance.getAttackPower(0, 1);
    const attackPowerTeamB = await instance.getAttackPower(0, 2);
    const defensePowerTeamA = await instance.getDefensePower(0, 1);
    const defensePowerTeamB = await instance.getDefensePower(0, 1);

    console.log({
      attackPowerTeamA: attackPowerTeamA.toString(),
      attackPowerTeamB: attackPowerTeamB.toString(),
      defensePowerTeamA: defensePowerTeamA.toString(),
      defensePowerTeamB: defensePowerTeamB.toString(),
    });

    await instance.withdraw(0, teamAArcher.address, {from: accounts[1]});
    
    console.log('name', war.name);
    console.log('attackerTeam', war.attackerTeam.toString());
    console.log('defenderTeam', war.defenderTeam.toString());
    console.log('winner', war.winner.toString());
    console.log('luck', war.luck.toString());
    console.log('isBadLuck', war.isBadLuck);
    console.log('attackerCasualty', war.attackerCasualty.toString());
    console.log('defenseCasualty', war.defenseCasualty.toString());
    console.log('-------');
    console.log('finalAttackPower', war.finalAttackPower.toString());
    console.log('finalDefensePower', war.finalDefensePower.toString());
    console.log('-------');
    console.log('percAtackerLosses', war.percAtackerLosses.toString());
    console.log('perDefenderLosses', war.percDefenderLosses.toString());
  });
});
