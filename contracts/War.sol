// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IUnitERC20.sol";

contract War {
    using SafeMath for uint256;

    uint256 private ONE = 10**18;
    uint256 private ONE_HUNDRED_PERCENT = 10**3;
    uint256 private TEAM_A = 1;
    uint256 private TEAM_B = 2;

    mapping(address => bool) private allowedTeamATokens;
    mapping(address => bool) private allowedTeamBTokens;
    mapping(uint256 => address[]) allowedTeamTokenAddresses;

    mapping(uint256 => mapping(address => mapping(address => uint256))) depositsByPlayer;
    mapping(uint256 => mapping(address => uint256)) teams;
    mapping(uint256 => mapping(uint256 => uint256)) attackPower;
    mapping(uint256 => mapping(uint256 => uint256)) defensePower;

    struct WarInfo {
        string name;
        uint256 finalAttackPower;
        uint256 finalDefensePower;
        uint256 percAttackerLosses;
        uint256 percDefenderLosses;
        uint256 attackerTeam;
        uint256 defenderTeam;
        uint256 winner;
        uint256 luck;
        bool isBadLuck;
        uint256 attackerCasualty;
        uint256 defenseCasualty;
    }

    WarInfo[] private wars;
    uint256 private currentWarId;

    event NewDeposit(
        address indexed player,
        address indexed token,
        uint256 indexed team,
        uint256 amount,
        uint256 attackPower,
        uint256 defensePower,
        uint256 newTeamAttackPower,
        uint256 newTeamDefensePower
    );

    event PowerChanged(
        uint256 indexed warId,
        uint256 initialAttackerPower,
        uint256 initialDefenderPower,
        uint256 attackerPowerIncrement,
        uint256 defenderPowerIncrement,
        bool isAttackerIncrementNegative,
        bool isDefenderIncrementNegative,
        uint256 newAttackerPower,
        uint256 newDefensePower
    );

    event TroopImprovement(
        uint256 indexed warId,
        uint256 indexed team,
        uint256 initialAttackerPower,
        uint256 initialDefenderPower,
        uint256 improvementAttackerPower,
        uint256 improvementDefensePower,
        uint256 newAttackerPower,
        uint256 newDefensePower
    );

    event TeamLosses(
        uint256 indexed warId,
        uint256 indexed team,
        bool indexed isAttacker,
        uint256 initialPower,
        uint256 power,
        uint256 otherTeamPower,
        uint256 losses
    );

    event Withdraw(
        uint256 indexed warId,
        address indexed player,
        address indexed tokenAddress,
        uint256 deposit,
        uint256 burned,
        uint256 net
    );

    function getCurrentWarInfo()
        public
        view
        returns (
            string memory name,
            uint256 finalAttackPower,
            uint256 finalDefensePower,
            uint256 percAttackerLosses,
            uint256 percDefenderLosses,
            uint256 attackerTeam,
            uint256 defenderTeam,
            uint256 winner,
            uint256 luck,
            bool isBadLuck,
            uint256 attackerCasualty,
            uint256 defenseCasualty
        )
    {
        name = wars[currentWarId].name;
        finalAttackPower = wars[currentWarId].finalAttackPower;
        finalDefensePower = wars[currentWarId].finalDefensePower;
        percAttackerLosses = wars[currentWarId].percAttackerLosses;
        percDefenderLosses = wars[currentWarId].percDefenderLosses;
        attackerTeam = wars[currentWarId].attackerTeam;
        winner = wars[currentWarId].winner;
        luck = wars[currentWarId].luck;
        isBadLuck = wars[currentWarId].isBadLuck;
        attackerCasualty = wars[currentWarId].attackerCasualty;
        defenseCasualty = wars[currentWarId].defenseCasualty;
    }

    function getAttackPower(uint256 warId, uint256 team)
        public
        view
        returns (uint256)
    {
        return attackPower[warId][team];
    }

    function getDefensePower(uint256 warId, uint256 team)
        public
        view
        returns (uint256)
    {
        return defensePower[warId][team];
    }

    function defineTokenTeam(
        uint256 warId,
        IUnitERC20 unit,
        uint256 team
    ) public {
        teams[warId][address(unit)] = team;
        allowedTeamTokenAddresses[team].push(address(unit));
    }

    function addWar(string calldata name) public {
        WarInfo memory war = WarInfo(name, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0);
        war.name = name;

        wars.push(war);
        currentWarId = wars.length - 1;
    }

    function deposit(IUnitERC20 unit, uint256 amount) public {
        address tokenAddress = address(unit);

        unit.transferFrom(msg.sender, address(this), amount);
        depositsByPlayer[currentWarId][tokenAddress][msg.sender] += amount;

        //identifying if the token is part from the TEAM_A or TEAM_B;
        uint256 team = teams[currentWarId][tokenAddress];

        uint256 troopAttackPower = unit.getAttackPower().mul(amount);
        uint256 troopDefensePower = unit.getAttackPower().mul(amount);

        //updating attack and defense powers
        attackPower[currentWarId][team] = attackPower[currentWarId][team].add(
            troopAttackPower
        );
        defensePower[currentWarId][team] = defensePower[currentWarId][team].add(
            troopDefensePower
        );

        emit NewDeposit(
            msg.sender,
            address(unit),
            team,
            amount,
            troopAttackPower,
            troopDefensePower,
            attackPower[currentWarId][team],
            defensePower[currentWarId][team]
        );
    }

    function _defineRandomParameters(uint256 id) public {
        WarInfo storage war = wars[id];
        war.attackerTeam = TEAM_A;
        war.defenderTeam = TEAM_B;
        war.attackerCasualty = 20;
        war.defenseCasualty = 80;
        war.luck = 20;
        war.isBadLuck = true;
    }

    function _calculateTroopImprovement(uint256 warId) public {
        uint256 attackImprovement = 0;
        uint256 defenseImprovement = 0;

        uint256 initialAttackePower = attackPower[warId][TEAM_A];
        uint256 initialDefensePower = defensePower[warId][TEAM_A];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_A].length; i++) {
            IUnitERC20 unit = IUnitERC20(allowedTeamTokenAddresses[1][i]);

            if (unit.getTroopImproveFactor() > 0) {
                attackImprovement = attackPower[warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                attackPower[warId][TEAM_A] = attackImprovement;

                defenseImprovement = defensePower[warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                defensePower[warId][TEAM_A] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            warId,
            TEAM_A,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[warId][TEAM_A],
            defensePower[warId][TEAM_A]
        );

        initialAttackePower = attackPower[warId][TEAM_B];
        initialDefensePower = defensePower[warId][TEAM_B];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_B].length; i++) {
            IUnitERC20 unit = IUnitERC20(allowedTeamTokenAddresses[1][i]);

            if (unit.getTroopImproveFactor() > 0) {
                attackImprovement = attackPower[warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                attackPower[warId][TEAM_B] = attackImprovement;

                defenseImprovement = defensePower[warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                defensePower[warId][TEAM_B] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            warId,
            TEAM_B,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[warId][TEAM_B],
            defensePower[warId][TEAM_B]
        );
    }

    function _calculateLuckImpact(uint256 id) public {
        WarInfo storage war = wars[id];

        uint256 initialAttackerPower = attackPower[id][war.attackerTeam];
        uint256 initialDefensePower = defensePower[id][war.defenderTeam];

        uint256 attackerPowerByLuck =
            initialAttackerPower.mul(war.luck).div(100);
        uint256 defensePowerByLuck = initialDefensePower.mul(war.luck).div(100);

        // the luck is in the attacker point of view
        if (war.isBadLuck) {
            war.finalAttackPower = initialAttackerPower - attackerPowerByLuck;
            war.finalDefensePower = initialDefensePower + defensePowerByLuck;
        } else {
            war.finalAttackPower = initialAttackerPower + attackerPowerByLuck;
            war.finalDefensePower = initialDefensePower - defensePowerByLuck;
        }

        emit PowerChanged(
            id,
            initialAttackerPower,
            initialDefensePower,
            attackerPowerByLuck,
            defensePowerByLuck,
            war.isBadLuck,
            !war.isBadLuck,
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    function _calculareMoraleImpact(uint256 id) public {
        WarInfo storage war = wars[id];

        uint256 initialAttackerPower = war.finalAttackPower;
        uint256 initialDefensePower = war.finalDefensePower;

        uint256 attackerMoraleImpactPerc =
            initialAttackerPower.mul(ONE_HUNDRED_PERCENT).div(
                initialDefensePower
            );
        uint256 defenseMoraleImpactPerc =
            initialDefensePower.mul(ONE_HUNDRED_PERCENT).div(
                initialAttackerPower
            );

        uint256 attackerMoraleImpact =
            initialAttackerPower
                .mul(attackerMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(10);
        uint256 defenseMoraleImpact =
            initialDefensePower
                .mul(defenseMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(10);

        if (attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT) {
            war.finalAttackPower = war.finalAttackPower.sub(
                attackerMoraleImpact
            );
            war.finalDefensePower = war.finalDefensePower.add(
                defenseMoraleImpact
            );
        } else {
            war.finalAttackPower = war.finalAttackPower.add(
                attackerMoraleImpact
            );
            war.finalDefensePower = war.finalDefensePower.sub(
                defenseMoraleImpact
            );
        }

        emit PowerChanged(
            id,
            initialAttackerPower,
            initialDefensePower,
            attackerMoraleImpactPerc,
            defenseMoraleImpactPerc,
            attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT,
            !(attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT),
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    function _calculateLosses(uint256 id) public {
        WarInfo storage war = wars[id];

        uint256 initialAttackerPower = attackPower[id][war.attackerTeam];
        uint256 initialDefensePower = defensePower[id][war.defenderTeam];

        if (war.finalAttackPower > war.finalDefensePower) {
            war.winner = war.attackerTeam;
        } else {
            war.winner = war.defenderTeam;
        }

        uint256 totalPower = war.finalAttackPower.add(war.finalDefensePower);

        war.percAttackerLosses = war
            .finalAttackPower
            .mul(ONE_HUNDRED_PERCENT)
            .div(totalPower);
        war.percAttackerLosses = ONE_HUNDRED_PERCENT.sub(
            war.percAttackerLosses
        );
        war.percDefenderLosses = war
            .finalDefensePower
            .mul(ONE_HUNDRED_PERCENT)
            .div(totalPower);
        war.percDefenderLosses = ONE_HUNDRED_PERCENT.sub(
            war.percDefenderLosses
        );

        emit TeamLosses(
            id,
            war.attackerTeam,
            true,
            initialAttackerPower,
            war.finalAttackPower,
            totalPower,
            war.percAttackerLosses
        );

        emit TeamLosses(
            id,
            war.defenderTeam,
            false,
            initialDefensePower,
            war.finalDefensePower,
            totalPower,
            war.percDefenderLosses
        );
    }

    function finishWar(uint256 id) public {
        WarInfo storage war = wars[id];

        _calculateTroopImprovement(id);
        _defineRandomParameters(id);
        _calculateLuckImpact(id);
        _calculareMoraleImpact(id);
        _calculateLosses(id);
    }

    function getPlayerDeposit(
        uint256 warId,
        address tokenAddress,
        address player
    ) public view returns (uint256) {
        return depositsByPlayer[warId][tokenAddress][player];
    }

    function withdraw(uint256 warId, IUnitERC20 unit) public {
        WarInfo storage war = wars[warId];

        address tokenAddress = address(unit);
        uint256 team = allowedTeamATokens[tokenAddress] ? TEAM_A : TEAM_B;
        uint256 depositAmount =
            depositsByPlayer[warId][tokenAddress][msg.sender];

        uint256 toBurnPerc =
            team == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;

        uint256 toBurnAmount =
            depositAmount.mul(toBurnPerc).div(ONE_HUNDRED_PERCENT);
        uint256 net = depositAmount - toBurnAmount;

        unit.burn(toBurnAmount);
        unit.transfer(msg.sender, net);

        emit Withdraw(
            warId,
            msg.sender,
            tokenAddress,
            depositAmount,
            toBurnAmount,
            net
        );
    }
}
