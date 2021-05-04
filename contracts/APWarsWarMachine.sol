// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IAPWarsBaseToken.sol";
import "./nfts/APWarsCollectibles.sol";
import "./IAPWarsUnit.sol";

/**
 * @title The war simulator for APWars Finance.
 * @author Vulug
 * @notice A player will use this contract to send troops by depositing unit tokens and getting them back home by
 *         withdrawing the remaining amounts. The war simulator will randomly select the attacker and defender team,
 *         so the player doesn't know if the system will use each unit's attack or defense power. The war is divided
 *         into two rounds: the first is completed by computing the battle between the teams. After the first stage,
 *         the winner will fight against the Dragon to collect the gold from the Dragon's pocket. At this point. A random
 *         value will define how much gold the army will get from the Dragon and how many troops will die fighting against the Dragon.
 *         The Dragon will burn all remaining gold that troop can't bring home.
 * @dev See the docs to understand how the battle system works. It is not so hard, but be guided by examples is a better way.
 */
contract APWarsWarMachine is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum WarStage {FIRST_ROUND, SECOND_ROUND, FINISHED, CLOSED}

    uint256 private constant ONE = 10**18;
    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant ONE_PERCENT = 10**2;
    uint256 private constant TEN_PERCENT = 10**3;
    uint256 private constant FIVE_PERCENT = 10**3 / 2;
    uint256 private constant TEAM_A = 1;
    uint256 private constant TEAM_B = 2;

    mapping(uint256 => address[]) private allowedTeamTokenAddresses;

    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private depositsByPlayer;
    mapping(uint256 => mapping(address => uint256)) private depositsByToken;

    mapping(uint256 => mapping(address => uint256)) private teams;
    mapping(uint256 => mapping(uint256 => uint256)) private attackPower;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private attackPowerByAddress;
    mapping(uint256 => mapping(uint256 => uint256)) private defensePower;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private defensePowerByAddress;

    uint256 private interval;

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
     * @param attackerLuck The attacker luck.
     * @param defenderLuck The defender luck.
     * @param isBadLuck Sepecifies if it is a bad luck (negative luck).
     * @param attackerCasualty The attacker casualty.
     * @param defenderCasualty The defender casualty.
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
        uint256 attackerLuck;
        uint256 defenderLuck;
        bool isBadLuck;
        uint256 attackerCasualty;
        uint256 defenderCasualty;
    }

    /**
     * @notice The first round war random parameters configuration.
     * @param randomTeamSource The random number used to define the attacker and defender.
     * @param attackerCasualty The attacker casualty pecentage.
     * @param defenderCasualty The defender casualty pecentage.
     * @param attackerLuck The luck pecentage.
     * @param defenderLuck The luck pecentage.
     * @param randomBadLuckSource The number used to defined if it is a bad luck (negative luck).
     */
    struct WarFirstRoundRandomParameters {
        uint256 randomTeamSource;
        uint256 attackerCasualty;
        uint256 defenderCasualty;
        uint256 attackerLuck;
        uint256 defenderLuck;
        uint256 randomBadLuckSource;
    }

    /**
     * @notice The second round war random parameters configuration.
     * @param unlockedPrize The percentual of the unlocked prize.
     * @param casualty The casualty in the second round.
     */
    struct WarSecondRoundRandomParameters {
        uint256 unlockedPrize;
        uint256 casualty;
    }

    /// @notice The wars information.
    /// @dev See the WarInfo struct.
    WarInfo[] public wars;

    /// @notice The current war id.
    uint256 public currentWarId;

    /// @notice The external random source hash.
    mapping(uint256 => bytes32) public externalRandomSourceHashes;

    /// @notice It stores the current stage per war.
    mapping(uint256 => WarStage) public warStage;

    /// @notice It stores the first round random parameters generated for a war.
    mapping(uint256 => WarFirstRoundRandomParameters)
        public warFirstRoundRandomParameters;

    /// @notice It stores the second round random parameters generated for a war.
    mapping(uint256 => WarSecondRoundRandomParameters)
        public secondRoundRandomParameters;

    /// @notice It stores the token prize to a War.
    mapping(uint256 => address) public tokenPrize;

    /// @notice It stores the timestamp when the second round is finished.
    mapping(uint256 => uint256) public secoundRoundFinishTimestamp;

    /// @notice It stores the total prize.
    mapping(uint256 => uint256) public totalPrize;

    /// @notice It stores the NFT collectible address.
    APWarsCollectibles public collectibles;

    /// @notice It stores the id of each elixir NFT.
    uint256[] public elixirsIds;

    /// @notice It stores the id of arcane's bok.
    uint256 public arcaneBookId;

    /// @notice It stores the id of beloved hater NFT.
    uint256 public belovedHaterId;

    /// @notice It stores the user alread withdrawn a token.
    mapping(address => mapping(address => bool)) public withdrawn;

    /**
     * @notice Fired when a user sends troops (token units) to war.
     * @param player The user address.
     * @param token The unit token address.
     * @param team The unit team.
     * @param amount The deposited amount.
     * @param attackPower The unit attack power.
     * @param newTeamAttackPower The team attack power after deposit.
     * @param newTeamDefensePower The team defense power after deposit.
     * @param belovedHaterImprovement The team defense power after deposit.
     */
    event NewDeposit(
        address indexed player,
        address indexed token,
        uint256 indexed team,
        uint256 amount,
        uint256 attackPower,
        uint256 defensePower,
        uint256 newTeamAttackPower,
        uint256 newTeamDefensePower,
        uint256 belovedHaterImprovement
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
     * @notice Fired when the contract calculates the first random parameters.
     * @param warId War id.
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param attackerCasualty The percentage of attacker casualty.
     * @param defenderCasualty The percentage of defender casualty.
     * @param attackerLuck The percentage of attacker luck.
     * @param defenderLuck The percentage of defender luck.
     * @param isBadLuck Specifies if is a bad luck (negative luck).
     */
    event FirstRoundRandomParameters(
        uint256 indexed warId,
        uint256 attackerTeam,
        uint256 defenderTeam,
        uint256 attackerCasualty,
        uint256 defenderCasualty,
        uint256 attackerLuck,
        uint256 defenderLuck,
        bool isBadLuck
    );

    /**
     * @notice Fired when the contract calculates the second round random parameters.
     * @param warId War id.
     * @param unlockedPrize The percentual of the unlocked prize.
     * @param casualty The casualty in the second round.
     */
    event SecondRoundRandomParameters(
        uint256 indexed warId,
        uint256 unlockedPrize,
        uint256 casualty
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
     * @notice Fired when the contract owner finishes a round.
     * @param warId War id.
     * @param sender Transaction sender.
     * @param externalRandomSource The revealed external random source.
     * @param winner The winner team.
     */
    event RoundFinished(
        uint256 indexed warId,
        uint256 indexed round,
        address sender,
        bytes32 externalRandomSource,
        uint256 winner,
        uint256 winnerLosses
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
        uint256 amountToBurn,
        uint256 amountToSave,
        uint256 burned,
        uint256 net
    );

    /**
     * @notice Fired when an user request to withdraw the prize after the second round of war.
     * @param warId War id.
     * @param player The player address.
     * @param tokenAddress The token prize address.
     * @param totalPower The team total power.
     * @param userTotalPower The user total power (to calculate the user share in the prize).
     * @param userShare The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event PrizeWithdraw(
        uint256 indexed warId,
        address indexed player,
        address indexed tokenAddress,
        uint256 totalPower,
        uint256 userTotalPower,
        uint256 userShare,
        uint256 burned,
        uint256 net
    );

    /**
     * @notice Fired when the owner closes the war.
     * @param warId War id.
     * @param sender The sender address.
     */
    event WarClosed(uint256 indexed warId, address indexed sender);

    /**
     * @notice It defines the interval to be used in the burn process when a war is finished. This function can be called once to avoid
     *         unfair game.
     * @param _interval The internal.
     */
    function defineInterval(uint256 _interval) public onlyOwner {
        require(interval == 0, "War:INTERVAL_ALREADY_DECLARED");
        interval = _interval;
    }

    function setup(
        uint256 _warId,
        IAPWarsBaseToken _tokenPrize,
        IAPWarsUnit[] calldata _teamA,
        IAPWarsUnit[] calldata _teamB,
        APWarsCollectibles _collectibles,
        uint256[] calldata _elixirsIds,
        uint256 _arcaneBookId,
        uint256 _belovedHaterId
    ) public onlyOwner {
        collectibles = _collectibles;
        elixirsIds = _elixirsIds;
        arcaneBookId = _arcaneBookId;
        belovedHaterId = _belovedHaterId;

        tokenPrize[_warId] = address(_tokenPrize);

        delete allowedTeamTokenAddresses[TEAM_A];
        delete allowedTeamTokenAddresses[TEAM_B];

        address tokenAddress = address(0);

        for (uint256 i = 0; i < _teamA.length; i++) {
            tokenAddress = address(_teamA[i]);
            teams[_warId][tokenAddress] = TEAM_A;
            allowedTeamTokenAddresses[TEAM_A].push(tokenAddress);
        }

        for (uint256 i = 0; i < _teamB.length; i++) {
            tokenAddress = address(_teamB[i]);
            teams[_warId][tokenAddress] = TEAM_B;
            allowedTeamTokenAddresses[TEAM_B].push(tokenAddress);
        }
    }

    /**
     * @notice It creates a new war and stores the hash of the external random source. It is a important value that will
     * be used to compute random numbers. When the contract owner finishes a war only the original value will be accepted
     * as the random source, it is useful to keep a fair game.
     * @param _name The war name.
     * @param _externalRandomSourceHash The has of the external random source.
     */
    function createWar(string calldata _name, bytes32 _externalRandomSourceHash)
        public
        onlyOwner
    {
        WarInfo memory war =
            WarInfo(_name, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0);
        wars.push(war);
        currentWarId = wars.length - 1;

        warStage[currentWarId] = WarStage.FIRST_ROUND;
        externalRandomSourceHashes[currentWarId] = _externalRandomSourceHash;
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
    function deposit(IAPWarsUnit _unit, uint256 _amount) public nonReentrant {
        WarInfo storage war = wars[currentWarId];
        address tokenAddress = address(_unit);

        //identifying if the token is part from the TEAM_A or TEAM_B;
        uint256 team = teams[currentWarId][tokenAddress];
        WarStage stage = warStage[currentWarId];

        require(stage == WarStage.FIRST_ROUND, "War:DEPOSIT_IS_BLOCKED");

        //transfering the amount to this contract and increase the user deposit amount
        _unit.transferFrom(msg.sender, address(this), _amount);
        depositsByPlayer[currentWarId][tokenAddress][
            msg.sender
        ] = depositsByPlayer[currentWarId][tokenAddress][msg.sender].add(
            _amount
        );
        depositsByToken[currentWarId][tokenAddress] = depositsByToken[
            currentWarId
        ][tokenAddress]
            .add(_amount);

        //getting the total power (attack and defense)
        uint256 troopAttackPower = _unit.getAttackPower().mul(_amount);
        uint256 troopDefensePower = _unit.getDefensePower().mul(_amount);

        //if the user has the Beloved Hate NFT it will increase the attack power in 1%
        uint256 belovedHaterImprovement = 0;
        if (collectibles.balanceOf(msg.sender, belovedHaterId) > 0) {
            belovedHaterImprovement = troopAttackPower.mul(ONE_PERCENT).div(
                ONE_HUNDRED_PERCENT
            );

            troopAttackPower = troopAttackPower.add(belovedHaterImprovement);
        }

        //updating attack and defense powers
        attackPowerByAddress[currentWarId][team][
            msg.sender
        ] = attackPowerByAddress[currentWarId][team][msg.sender].add(
            troopAttackPower
        );
        attackPower[currentWarId][team] = attackPower[currentWarId][team].add(
            troopAttackPower
        );
        defensePowerByAddress[currentWarId][team][
            msg.sender
        ] = defensePowerByAddress[currentWarId][team][msg.sender].add(
            troopDefensePower
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
            defensePower[currentWarId][team],
            belovedHaterImprovement
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
    function _defineFirstRoundRandomParameters(
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
        war.attackerLuck = random(
            _warId,
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.attackerLuck);
        war.defenderLuck = random(
            _warId,
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.defenderLuck);

        uint256 randomBadLuckSource =
            random(_warId, _externalRandomSource, salt, ONE_HUNDRED_PERCENT);

        war.isBadLuck = randomBadLuckSource > ONE_HUNDRED_PERCENT / 2;

        warFirstRoundRandomParameters[_warId] = WarFirstRoundRandomParameters(
            randomTeamSource,
            war.attackerCasualty,
            war.defenderCasualty,
            war.attackerLuck,
            war.defenderLuck,
            randomBadLuckSource
        );

        emit FirstRoundRandomParameters(
            _warId,
            war.attackerTeam,
            war.defenderTeam,
            war.attackerCasualty,
            war.defenderCasualty,
            war.attackerLuck,
            war.defenderLuck,
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
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_A][i]);
            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[_warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[_warId][TEAM_A] = attackImprovement;

                defenseImprovement = defensePower[_warId][TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

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
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_B][i]);

            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[_warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[_warId][TEAM_B] = attackImprovement;

                defenseImprovement = defensePower[_warId][TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

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
            initialAttackPower.mul(war.attackerLuck).div(ONE_HUNDRED_PERCENT);
        uint256 defensePowerByLuck =
            initialDefensePower.mul(war.defenderLuck).div(ONE_HUNDRED_PERCENT);

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
    function _calculateMoraleImpact(uint256 _warId) internal {
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

        if (war.finalAttackPower == 0) {
            war.percAttackerLosses = 0;
        } else {
            war.percAttackerLosses = war
                .finalAttackPower
                .mul(ONE_HUNDRED_PERCENT)
                .div(totalPower);
            war.percAttackerLosses = ONE_HUNDRED_PERCENT.sub(
                war.percAttackerLosses
            );
        }

        if (war.finalDefensePower == 0) {
            war.percDefenderLosses = 0;
        } else {
            war.percDefenderLosses = war
                .finalDefensePower
                .mul(ONE_HUNDRED_PERCENT)
                .div(totalPower);
            war.percDefenderLosses = ONE_HUNDRED_PERCENT.sub(
                war.percDefenderLosses
            );
        }

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

    /**
     * @notice It finishes the first round of a war. All the random parameters will be computed by revealing the original
     * external random source. This function is a templated method pattern which calls other helper functions. At the end of
     * the execution the war is changed to second round and the survivors can figth to get the gold from the dragon.
     * @param _warId War id.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishFirstRound(uint256 _warId, bytes32 _externalRandomSource)
        public
        onlyOwner
    {
        WarInfo storage war = wars[_warId];

        _calculateTroopImprovement(_warId);
        _defineFirstRoundRandomParameters(_warId, _externalRandomSource);
        _calculateLuckImpact(_warId);

        // if there is no other side there is no morale impact
        if (war.finalAttackPower > 0 && war.finalDefensePower > 0) {
            _calculateMoraleImpact(_warId);
        }
        _calculateLosses(_warId);

        warStage[_warId] = WarStage.SECOND_ROUND;

        emit RoundFinished(
            _warId,
            1,
            msg.sender,
            _externalRandomSource,
            war.winner,
            war.winner == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses
        );
    }

    /**
     * @notice It finishes the first round of a war. All the random parameters will be computed by revealing the original
     * external random source. This function is a templated method pattern which calls other helper functions. At the end of
     * the execution the war is changed to second round and the survivors can figth to get the gold from the dragon.
     * @param _warId War id.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishSecondRound(uint256 _warId, bytes32 _externalRandomSource)
        public
        onlyOwner
    {
        WarInfo storage war = wars[_warId];
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenPrize[_warId]);

        secondRoundRandomParameters[_warId].unlockedPrize = random(
            _warId,
            _externalRandomSource,
            0,
            ONE_HUNDRED_PERCENT
        );
        secondRoundRandomParameters[_warId].casualty = random(
            _warId,
            _externalRandomSource,
            secondRoundRandomParameters[_warId].unlockedPrize,
            ONE_HUNDRED_PERCENT
        );

        warStage[_warId] = WarStage.FINISHED;
        secoundRoundFinishTimestamp[_warId] = block.timestamp;
        totalPrize[_warId] = token.balanceOf(address(this));

        //calculating the new losses after the second round
        uint256 losses =
            war.winner == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;
        uint256 newLosses =
            losses
                .mul(secondRoundRandomParameters[_warId].casualty)
                .div(ONE_HUNDRED_PERCENT)
                .add(losses);

        if (newLosses > ONE_HUNDRED_PERCENT) {
            newLosses = ONE_HUNDRED_PERCENT;
        }

        if (war.winner == war.attackerTeam) {
            war.percAttackerLosses = newLosses;
        } else {
            war.percDefenderLosses = newLosses;
        }

        emit SecondRoundRandomParameters(
            _warId,
            secondRoundRandomParameters[_warId].unlockedPrize,
            secondRoundRandomParameters[_warId].casualty
        );
        emit RoundFinished(
            _warId,
            2,
            msg.sender,
            _externalRandomSource,
            war.winner,
            newLosses
        );
    }

    /**
     * @notice It a help function to burn tokens by team.
     * @dev This function is a helper function called by closeWar.
     * @param _team Team number.
     */
    function _burnTokensByTeam(uint256 _team) internal {
        for (uint256 i = 0; i < allowedTeamTokenAddresses[_team].length; i++) {
            IAPWarsUnit unit = IAPWarsUnit(allowedTeamTokenAddresses[_team][i]);

            uint256 amount = unit.balanceOf(address(this));
            if (amount > 0) {
                unit.burn(amount);
            }
        }
    }

    /**
     * @notice It closes the war. After the war is finished all the remaining token balances are burned.
     * @param _warId War id.
     */
    function closeWar(uint256 _warId) public onlyOwner {
        require(
            secoundRoundFinishTimestamp[_warId] + interval <= block.timestamp,
            "War:INVALID_TIMESTAMP"
        );
        warStage[_warId] = WarStage.CLOSED;

        _burnTokensByTeam(TEAM_A);
        _burnTokensByTeam(TEAM_B);

        emit WarClosed(_warId, msg.sender);
    }

    function getPlayerInfo(
        uint256 _warId,
        address _tokenAddress,
        address _player
    )
        public
        view
        returns (
            uint256 depositAmount,
            uint256 totalAttackPower,
            uint256 totalDefensePower
        )
    {
        uint256 team = teams[_warId][_tokenAddress];
        depositAmount = depositsByPlayer[_warId][_tokenAddress][_player];
        totalAttackPower = attackPowerByAddress[_warId][team][_player];
        totalDefensePower = defensePowerByAddress[_warId][team][_player];
    }

    function getWarInfo(
        uint256 _warId,
        uint256 _team,
        address[] calldata _tokenAddresses
    )
        public
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalAttackPower,
            uint256 totalDefensePower
        )
    {
        address tokenAddress = address(0);

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            totalDepositAmount = totalDepositAmount.add(
                depositsByToken[_warId][tokenAddress]
            );
        }

        totalAttackPower = attackPower[_warId][_team];
        totalDefensePower = defensePower[_warId][_team];
    }

    /**
     * @notice It withdraws the remaining amount of a unit token after the war. This function get the troop back to home.
     * @param _warId War id.
     * @param _unit Unit token address.
     */
    function withdraw(uint256 _warId, IAPWarsUnit _unit) public nonReentrant {
        WarInfo storage war = wars[_warId];
        address tokenAddress = address(_unit);

        require(
            !withdrawn[msg.sender][address(_unit)],
            "War:ALREADY_WITHDRAWN"
        );

        require(
            teams[_warId][tokenAddress] == TEAM_A ||
                teams[_warId][tokenAddress] == TEAM_B,
            "War:INVALID_TOKEN_ADDRESS"
        );
        require(
            warStage[_warId] == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAW"
        );

        uint256 team = teams[currentWarId][tokenAddress];
        uint256 depositAmount =
            depositsByPlayer[_warId][tokenAddress][msg.sender];

        uint256 toBurnPerc =
            team == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;

        uint256 amountToSave = 0;

        if (_unit.getTroopImproveFactor() > 0) {
            if (collectibles.balanceOf(msg.sender, arcaneBookId) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        } else {
            if (collectibles.balanceOf(msg.sender, elixirsIds[0]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, elixirsIds[1]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT + FIVE_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, elixirsIds[2]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        }

        if (amountToSave > toBurnPerc) {
            toBurnPerc = 0;
        } else {
            toBurnPerc = toBurnPerc.sub(amountToSave);
        }

        uint256 amountToBurn =
            depositAmount.mul(toBurnPerc).div(ONE_HUNDRED_PERCENT);
        uint256 net = depositAmount - amountToBurn;

        _unit.burn(amountToBurn);

        //avoinding rounding erros to the last user
        if (_unit.balanceOf(address(this)) < net) {
            _unit.transfer(msg.sender, _unit.balanceOf(address(this)));
        } else {
            _unit.transfer(msg.sender, net);
        }

        withdrawn[msg.sender][address(_unit)] = true;

        emit Withdraw(
            _warId,
            msg.sender,
            tokenAddress,
            depositAmount,
            toBurnPerc,
            amountToSave,
            amountToBurn,
            net
        );
    }

    /**
     * @notice It returns the total prize locked when the war was finished.
     * @param _warId War id.
     */
    function getTotalPrize(uint256 _warId) public view returns (uint256) {
        return totalPrize[_warId];
    }

    //TODO: Check if the user can run this method
    /**
     * @notice It withdraws the unlocked prize and burns the locked prize for each user.
     *         The total prize is the token prize total balance when the war is finisehd.
     *         The user share corresponds to the proportion of user total power and the the team
     *         total power.
     * @param _warId War id.
     */
    function withdrawPrize(uint256 _warId) public nonReentrant {
        WarInfo storage war = wars[_warId];
        address tokenAddress = tokenPrize[_warId];
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenAddress);

        require(
            warStage[_warId] == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAL_PRIZE"
        );

        bool isAttacker = war.attackerTeam == war.winner;
        uint256 teamTotalPower =
            isAttacker
                ? attackPower[_warId][war.winner]
                : defensePower[_warId][war.winner];
        uint256 userTotalPower =
            isAttacker
                ? attackPowerByAddress[_warId][war.winner][msg.sender]
                : defensePowerByAddress[_warId][war.winner][msg.sender];

        uint256 userShare =
            userTotalPower.mul(ONE_HUNDRED_PERCENT).div(teamTotalPower);
        uint256 userPrize =
            totalPrize[_warId].mul(userShare).div(ONE_HUNDRED_PERCENT);
        uint256 amountToBurn =
            userPrize
                .mul(secondRoundRandomParameters[_warId].unlockedPrize)
                .div(ONE_HUNDRED_PERCENT);
        uint256 net = userPrize - amountToBurn;

        token.burn(amountToBurn);

        //avoinding rounding errors to the last user
        if (token.balanceOf(address(this)) < net) {
            token.transfer(msg.sender, token.balanceOf(address(this)));
        } else {
            token.transfer(msg.sender, net);
        }

        emit PrizeWithdraw(
            _warId,
            msg.sender,
            tokenAddress,
            teamTotalPower,
            userTotalPower,
            userShare,
            amountToBurn,
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
            hash == externalRandomSourceHashes[_warId],
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
