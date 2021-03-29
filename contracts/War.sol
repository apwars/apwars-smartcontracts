// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IUnitERC20.sol";

/**
 * @title The war simulator for APWars Finance.
 * @author Vulug
 * @notice A player will use this contract to send troops by depositing unit tokens and getting them back home by
 *         withdrawing the remaining amounts. The war simulator will randomly select the attacker and defender team,
 *         so the player doesn't know if the system will use each unit's attack or defense power. The war is divided
 *         into two rounds: the first is completed by computing the battle between the teams. After the first stage,
 *         the winner will fight against the Dragon to collect the gold from the Dragon's pocket. At this point, the
 *         player will not lose any troops. A random value will define how much gold the army will get from the Dragon.
 *         The Dragon will burn all remaining gold that troop can't bring home.
 * @dev See the docs to understand how the battle system works. It is not so hard, but be guided by examples is a better way.
 */
contract War {
    using SafeMath for uint256;

    enum WarStage {FIRST_ROUND, SECOND_ROUND, FINISHED}

    uint256 private constant ONE = 10**18;
    uint256 private constant ONE_HUNDRED_PERCENT = 10**3;
    uint256 private constant TEN_PERCENT = 10;
    uint256 private constant TEAM_A = 1;
    uint256 private constant TEAM_B = 2;

    mapping(address => bool) private allowedTeamATokens;
    mapping(address => bool) private allowedTeamBTokens;
    mapping(uint256 => address[]) private allowedTeamTokenAddresses;

    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private depositsByPlayer;
    mapping(uint256 => mapping(address => uint256)) private teams;
    mapping(uint256 => mapping(uint256 => uint256)) private attackPower;
    mapping(uint256 => mapping(uint256 => uint256)) private defensePower;

    /**
     * @notice War information.
     * @param name The war name.
     * @param finalAttackPower The final attack power.
     * @param finalDefensePower The final defense power.
     * @param percAttackerLosses The percentage of losses from the attacker team.
     * @param percDefenderLosses The percentage of losses from the defender team.
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param winner The winner team number.
     * @param luck The attacker luck.
     * @param isBadLuck Sepecifies if it is a bad luck (negative luck).
     * @param attackerCasualty The attacker casualty.
     * @param defenderCasualty The defender casualty.
     * @param externalRandomSourceHash The external random source hash.
     */
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
        uint256 defenderCasualty;
        bytes32 externalRandomSourceHash;
    }

    /**
     * @notice The war random parameters configuration.
     * @param randomTeamSource The random number used to define the attacker and defender.
     * @param attackerCasualty The attacker casualty pecentage.
     * @param defenderCasualty The defender casualty pecentage.
     * @param luck The luck pecentage.
     * @param randomBadLuckSource The number used to defined if it is a bad luck (negative luck).
     */
    struct WarRandomParameters {
        uint256 randomTeamSource;
        uint256 attackerCasualty;
        uint256 defenderCasualty;
        uint256 luck;
        uint256 randomBadLuckSource;
    }

    /// @notice The wars information.
    /// @dev See the WarInfo struct.
    WarInfo[] public wars;

    /// @notice The current war id.
    uint256 public currentWarId;

    /// @notice It stores the current stage per war.
    mapping(uint256 => WarStage) public warStage;

    /// @notice It stores the random parameters generated for a war.
    mapping(uint256 => WarRandomParameters) public warRandomParameters;

    /**
     * @notice Fired when a user sends troops (token units) to war.
     * @param player The user address.
     * @param token The unit token address.
     * @param team The unit team.
     * @param amount The deposited amount.
     * @param attackPower The unit attack power.
     * @param newTeamAttackPower The team attack power after deposit.
     * @param newTeamDefensePower The team defense power after deposit.
     */
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

    /**
     * @notice Fired when the contract calculates the a new power for the teams.
     * @param warId War id.
     * @param initialAttackPower The initial attacker power.
     * @param initialDefensePower The initial defense power.
     * @param attackerPowerIncrement The calculated attack increment.
     * @param defenderPowerIncrement The calculated defense increment.
     * @param isAttackerIncrementNegative Specifies if the increment is negative.
     * @param isDefenderIncrementNegative Specifies if the increment is negative.
     * @param newAttackPower The attack power after changes.
     * @param newDefensePower The defense power after changes.
     */
    event PowerChanged(
        uint256 indexed warId,
        uint256 initialAttackPower,
        uint256 initialDefensePower,
        uint256 attackerPowerIncrement,
        uint256 defenderPowerIncrement,
        bool isAttackerIncrementNegative,
        bool isDefenderIncrementNegative,
        uint256 newAttackPower,
        uint256 newDefensePower
    );

    /**
     * @notice Fired when the contract calculates the team improvement.
     * @param warId War id.
     * @param team The improved team number.
     * @param initialAttackPower The initial attacker power.
     * @param initialDefensePower The initial defense power.
     * @param improvementAttackPower The calculated attack improvement.
     * @param improvementDefensePower The calculated defense improvement.
     * @param newAttackPower The attack power after improvement.
     * @param newDefensePower The defense power after improvement.
     */
    event TroopImprovement(
        uint256 indexed warId,
        uint256 indexed team,
        uint256 initialAttackPower,
        uint256 initialDefensePower,
        uint256 improvementAttackPower,
        uint256 improvementDefensePower,
        uint256 newAttackPower,
        uint256 newDefensePower
    );

    /**
     * @notice Fired when the contract calculates the random parameters.
     * @param warId War id.
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param attackerCasualty The percentage of attacker casualty.
     * @param defenderCasualty The percentage of defender casualty.
     * @param luck The percentage of attacker luck.
     * @param isBadLuck Specifies if is a bad luck (negative luck).
     */
    event RandomParameters(
        uint256 indexed warId,
        uint256 attackerTeam,
        uint256 defenderTeam,
        uint256 attackerCasualty,
        uint256 defenderCasualty,
        uint256 luck,
        bool isBadLuck
    );

    /**
     * @notice Fired when the contract calculates the team losses.
     * @param warId War id.
     * @param team The team number.
     * @param isAttacker Specifies if the team is the attacker.
     * @param initialPower Specifies the team's initial power.
     * @param power Specifies the team's final power.
     * @param otherTeamPower Specifies the other team's final power.
     * @param losses Specifies the losses percentage.
     */
    event TeamLosses(
        uint256 indexed warId,
        uint256 indexed team,
        bool indexed isAttacker,
        uint256 initialPower,
        uint256 power,
        uint256 otherTeamPower,
        uint256 losses
    );

    /**
     * @notice Fired when the contract owner finishes the war.
     * @param warId War id.
     * @param sender Transaction sender.
     * @param externalRandomSource The revealed external random source.
     * @param winner The winner team.
     */
    event FirstRoundFinished(
        uint256 indexed warId,
        address sender,
        bytes32 externalRandomSource,
        uint256 winner
    );

    /**
     * @notice Fired when an user request to withdraw the amount after a war.
     * @param warId War id.
     * @param player The player address.
     * @param tokenAddress The unit token address.
     * @param deposit The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event Withdraw(
        uint256 indexed warId,
        address indexed player,
        address indexed tokenAddress,
        uint256 deposit,
        uint256 burned,
        uint256 net
    );

    /**
     * @notice It returns the total attack power to a specified team.
     * @param _warId War id.
     * @param _team The team.
     * @return The computed total attack power.
     */
    function getAttackPower(uint256 _warId, uint256 _team)
        public
        view
        returns (uint256)
    {
        return attackPower[_warId][_team];
    }

    /**
     * @notice It returns the total defense power to a specified team.
     * @param _warId War id.
     * @param _team The team.
     * @return The computed total defense power.
     */
    function getDefensePower(uint256 _warId, uint256 _team)
        public
        view
        returns (uint256)
    {
        return defensePower[_warId][_team];
    }

    //TODO: restrict to only owner
    function defineTokenTeam(
        uint256 warId,
        IUnitERC20 unit,
        uint256 team
    ) public {
        teams[warId][address(unit)] = team;
        allowedTeamTokenAddresses[team].push(address(unit));
    }

    //TODO: restrict to only owner
    /**
     * @notice It creates a new war and stores the hash of the external random source. It is a important value that will
     * be used to compute random numbers. When the contract owner finishes a war only the original value will be accepted
     * as the random source, it is useful to keep a fair game.
     * @param _name The war name.
     * @param _externalRandomSourceHash The has of the external random source.
     */
    function createWar(string calldata _name, bytes32 _externalRandomSourceHash)
        public
    {
        WarInfo memory war =
            WarInfo(
                _name,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                false,
                0,
                0,
                _externalRandomSourceHash
            );
        wars.push(war);
        currentWarId = wars.length - 1;

        warStage[currentWarId] = WarStage.FIRST_ROUND;
    }

    /**
     * @notice The way to send troops to war is depositing unit tokens, each unit token has attack and defense power and by
     * depositing the user is inscreasing the team power. Both sides do not for if they will attack or defense, so the rigth way
     * to fish this war is send the maximum amount of troops! The method uses the currentWarId storage variable.
     * This method needs to receive the approval from the unit token contract to transfer the specified amount.
     * If the war is in the second round only winners can send more troops to collect more gold.
     * @param _unit Unit token address.
     * @param _amount How many troops the user is sending to war.
     */
    function deposit(IUnitERC20 _unit, uint256 _amount) public {
        WarInfo storage war = wars[currentWarId];
        address tokenAddress = address(_unit);

        //identifying if the token is part from the TEAM_A or TEAM_B;
        uint256 team = teams[currentWarId][tokenAddress];
        WarStage stage = warStage[currentWarId];

        require(stage == WarStage.FIRST_ROUND, "War:DEPOSIT_IS_BLOCKED");

        //transfering the amount to this contranct and increase the user deposit amount
        _unit.transferFrom(msg.sender, address(this), _amount);
        depositsByPlayer[currentWarId][tokenAddress][
            msg.sender
        ] = depositsByPlayer[currentWarId][tokenAddress][msg.sender].add(
            _amount
        );

        //getting the total power (attack and defense)
        uint256 troopAttackPower = _unit.getAttackPower().mul(_amount);
        uint256 troopDefensePower = _unit.getAttackPower().mul(_amount);

        //updating attack and defense powers
        attackPower[currentWarId][team] = attackPower[currentWarId][team].add(
            troopAttackPower
        );
        defensePower[currentWarId][team] = defensePower[currentWarId][team].add(
            troopDefensePower
        );

        emit NewDeposit(
            msg.sender,
            tokenAddress,
            team,
            _amount,
            troopAttackPower,
            troopDefensePower,
            attackPower[currentWarId][team],
            defensePower[currentWarId][team]
        );
    }

    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @param _warId War id.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @dev See the docs to understand how it works. It is not so hard, but be guided by examples is a better way.
     * @param _warId War id.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function _defineRandomParameters(
        uint256 _warId,
        bytes32 _externalRandomSource
    ) internal {
        WarInfo storage war = wars[_warId];
        uint256 salt = 0;

        uint256 randomTeamSource =
            random(_warId, _externalRandomSource, salt, ONE_HUNDRED_PERCENT);
        bool isTeamA = randomTeamSource > ONE_HUNDRED_PERCENT / 2;

        war.attackerTeam = isTeamA ? TEAM_A : TEAM_B;
        war.defenderTeam = !isTeamA ? TEAM_A : TEAM_B;

        salt = salt.add(randomTeamSource);

        war.attackerCasualty = random(
            _warId,
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT
        );
        salt = salt.add(war.attackerCasualty);
        war.defenderCasualty = random(
            _warId,
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT
        );
        salt = salt.add(war.defenderCasualty);
        war.luck = random(
            _warId,
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.luck);

        uint256 randomBadLuckSource =
            random(_warId, _externalRandomSource, salt, ONE_HUNDRED_PERCENT);

        war.isBadLuck = randomBadLuckSource > ONE_HUNDRED_PERCENT / 2;

        warRandomParameters[_warId] = WarRandomParameters(
            randomTeamSource,
            war.attackerCasualty,
            war.defenderCasualty,
            war.luck,
            randomBadLuckSource
        );

        emit RandomParameters(
            _warId,
            war.attackerTeam,
            war.defenderTeam,
            war.attackerCasualty,
            war.defenderCasualty,
            war.luck,
            war.isBadLuck
        );
    }

    //TODO: refactor the code to reduce the amount of duplicated code.
    /**
     * @notice It calculates the troop improvement by analysing if a specified unit has a troop impact factor, which is a percentual by unit.
     * @param _warId War id.
     */
    function _calculateTroopImprovement(uint256 _warId) internal {
        uint256 attackImprovement = 0;
        uint256 defenseImprovement = 0;

        uint256 initialAttackePower = attackPower[_warId][TEAM_A];
        uint256 initialDefensePower = defensePower[_warId][TEAM_A];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_A].length; i++) {
            IUnitERC20 unit = IUnitERC20(allowedTeamTokenAddresses[1][i]);

            if (unit.getTroopImproveFactor() > 0) {
                attackImprovement = attackPower[_warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                attackPower[_warId][TEAM_A] = attackImprovement;

                defenseImprovement = defensePower[_warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                defensePower[_warId][TEAM_A] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            _warId,
            TEAM_A,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[_warId][TEAM_A],
            defensePower[_warId][TEAM_A]
        );

        initialAttackePower = attackPower[_warId][TEAM_B];
        initialDefensePower = defensePower[_warId][TEAM_B];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_B].length; i++) {
            IUnitERC20 unit = IUnitERC20(allowedTeamTokenAddresses[1][i]);

            if (unit.getTroopImproveFactor() > 0) {
                attackImprovement = attackPower[_warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                attackPower[_warId][TEAM_B] = attackImprovement;

                defenseImprovement = defensePower[_warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(unit.balanceOf(address(this)).div(ONE));

                defensePower[_warId][TEAM_B] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            _warId,
            TEAM_B,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[_warId][TEAM_B],
            defensePower[_warId][TEAM_B]
        );
    }

    /**
     * @notice It calculates the luck of a team. The luck of a team is the same amount of badluck to another.
     *         This function uses the pre-calculated random luck percentual.
     * @param _warId War id.
     */
    function _calculateLuckImpact(uint256 _warId) internal {
        WarInfo storage war = wars[_warId];

        uint256 initialAttackPower = attackPower[_warId][war.attackerTeam];
        uint256 initialDefensePower = defensePower[_warId][war.defenderTeam];

        uint256 attackerPowerByLuck =
            initialAttackPower.mul(war.luck).div(ONE_HUNDRED_PERCENT);
        uint256 defensePowerByLuck =
            initialDefensePower.mul(war.luck).div(ONE_HUNDRED_PERCENT);

        // the luck is in the attacker point of view
        if (war.isBadLuck) {
            war.finalAttackPower = initialAttackPower - attackerPowerByLuck;
            war.finalDefensePower = initialDefensePower + defensePowerByLuck;
        } else {
            war.finalAttackPower = initialAttackPower + attackerPowerByLuck;
            war.finalDefensePower = initialDefensePower - defensePowerByLuck;
        }

        emit PowerChanged(
            _warId,
            initialAttackPower,
            initialDefensePower,
            attackerPowerByLuck,
            defensePowerByLuck,
            war.isBadLuck,
            !war.isBadLuck,
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    /**
     * @notice It calculates the morale from both sides.
     * @param _warId War id.
     */
    function _calculareMoraleImpact(uint256 _warId) internal {
        WarInfo storage war = wars[_warId];

        uint256 initialAttackPower = war.finalAttackPower;
        uint256 initialDefensePower = war.finalDefensePower;

        uint256 attackerMoraleImpactPerc =
            initialAttackPower.mul(ONE_HUNDRED_PERCENT).div(
                initialDefensePower
            );
        uint256 defenseMoraleImpactPerc =
            initialDefensePower.mul(ONE_HUNDRED_PERCENT).div(
                initialAttackPower
            );

        uint256 attackerMoraleImpact =
            initialAttackPower
                .mul(attackerMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(TEN_PERCENT);
        uint256 defenseMoraleImpact =
            initialDefensePower
                .mul(defenseMoraleImpactPerc)
                .div(ONE_HUNDRED_PERCENT)
                .div(TEN_PERCENT);

        // if the morale impact is greater than 100% it indicates that the team
        // has more power than other, so we will try to create a balance.
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
            _warId,
            initialAttackPower,
            initialDefensePower,
            attackerMoraleImpactPerc,
            defenseMoraleImpactPerc,
            attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT,
            !(attackerMoraleImpactPerc > ONE_HUNDRED_PERCENT),
            war.finalAttackPower,
            war.finalDefensePower
        );
    }

    /**
     * @notice It calculates the losses from the both sides. This function uses the pre-calculated random losses percentual.
     * @param _warId War id.
     */
    function _calculateLosses(uint256 _warId) internal {
        WarInfo storage war = wars[_warId];

        uint256 initialAttackPower = attackPower[_warId][war.attackerTeam];
        uint256 initialDefensePower = defensePower[_warId][war.defenderTeam];

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
            _warId,
            war.attackerTeam,
            true,
            initialAttackPower,
            war.finalAttackPower,
            totalPower,
            war.percAttackerLosses
        );

        emit TeamLosses(
            _warId,
            war.defenderTeam,
            false,
            initialDefensePower,
            war.finalDefensePower,
            totalPower,
            war.percDefenderLosses
        );
    }

    //TODO: restrict to only owner
    /**
     * @notice It finishes the first round of a war. All the random parameters will be computed by revealing the original
     * external random source. This function is a templated method pattern which calls other helper functions. At the end of
     * the execution the war is changed to second round and the survivors can figth to get the gold from the dragon.
     * @param _warId War id.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishFirstRound(uint256 _warId, bytes32 _externalRandomSource)
        public
    {
        WarInfo storage war = wars[_warId];

        _calculateTroopImprovement(_warId);
        _defineRandomParameters(_warId, _externalRandomSource);
        _calculateLuckImpact(_warId);
        _calculareMoraleImpact(_warId);
        _calculateLosses(_warId);

        warStage[_warId] = WarStage.SECOND_ROUND;

        emit FirstRoundFinished(
            _warId,
            msg.sender,
            _externalRandomSource,
            war.winner
        );
    }

    /**
     * @notice It returns the deposited amount of a specified unit token.
     * @param _warId War id.
     * @param _tokenAddress The specified unit token address to check the user's amount.
     * @param _player The player' address to check the deposited amount.
     * @return The deposited amount.
     */
    function getPlayerDeposit(
        uint256 _warId,
        address _tokenAddress,
        address _player
    ) public view returns (uint256) {
        return depositsByPlayer[_warId][_tokenAddress][_player];
    }

    // TODO: Add non-reentracy
    //       Check the war state
    //       Subtract the deposited amount or control the requested amount
    /**
     * @notice It withdraws the remaining amount of a unit token after the war. This function get the troop back to home.
     * @param _warId War id.
     * @param _unit Unit token address.
     */
    function withdraw(uint256 _warId, IUnitERC20 _unit) public {
        WarInfo storage war = wars[_warId];

        address tokenAddress = address(_unit);
        uint256 team = allowedTeamATokens[tokenAddress] ? TEAM_A : TEAM_B;
        uint256 depositAmount =
            depositsByPlayer[_warId][tokenAddress][msg.sender];

        uint256 toBurnPerc =
            team == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;

        uint256 toBurnAmount =
            depositAmount.mul(toBurnPerc).div(ONE_HUNDRED_PERCENT);
        uint256 net = depositAmount - toBurnAmount;

        _unit.burn(toBurnAmount);
        _unit.transfer(msg.sender, net);

        emit Withdraw(
            _warId,
            msg.sender,
            tokenAddress,
            depositAmount,
            toBurnAmount,
            net
        );
    }

    /**
     * @notice It returns the hash of a bytes32 parameters. Used to help users to configure a new war.
     * @param externalRandomSource A bytes32 external source to generate random numbers. This value will be combined with
     * others random data from the current state of the blockchain.
     */
    function hashExternalRandomSource(bytes32 externalRandomSource)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(externalRandomSource));
    }

    /**
     * @notice It generates a pseudo random numbers based on a external random source defined when the war was created.
     * @dev The externalRandomSource parameter is the original value. The hash of this value must be set when
     *      the war is created. To help this process you can user the hashExternalRandomSource function. It is a public
     *      function to help aditors verify the generated random numbers at the end of a war stage.
     * @param _warId War id.
     * @param _externalRandomSource The original external random source.
     * @param _salt A salt to generate random numbers using the same external random source.
     * @param _maxNumber The max number to be generated, used to create a range of random number.
     * @return Then computed pseudo random number.
     */
    function random(
        uint256 _warId,
        bytes32 _externalRandomSource,
        uint256 _salt,
        uint256 _maxNumber
    ) public view returns (uint256) {
        WarInfo storage war = wars[_warId];

        bytes32 hash = hashExternalRandomSource(_externalRandomSource);

        require(
            hash == war.externalRandomSourceHash,
            "War:INVALID_EXTERNAL_RANDOM_SOURCE"
        );

        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        bytes32 _structHash =
            keccak256(
                abi.encode(
                    _blockhash,
                    gasLeft,
                    wars.length,
                    _salt,
                    _externalRandomSource
                )
            );
        uint256 _randomNumber = uint256(_structHash);

        assembly {
            _randomNumber := add(mod(_randomNumber, _maxNumber), 1)
        }

        return _randomNumber;
    }
}
