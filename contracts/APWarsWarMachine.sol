// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IAPWarsBaseToken.sol";
import "./nfts/APWarsCollectibles.sol";
import "./utils/APWarsBurnManagerV2.sol";
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

    mapping(address => mapping(address => uint256)) private depositsByPlayer;
    mapping(address => uint256) private depositsByToken;

    mapping(address => uint256) private teams;
    mapping(uint256 => uint256) private attackPower;
    mapping(uint256 => mapping(address => uint256))
        private attackPowerByAddress;
    mapping(uint256 => uint256) private defensePower;
    mapping(uint256 => mapping(address => uint256))
        private defensePowerByAddress;

    address private tokenPrize;
    address[] private players;
    mapping(address => bool) private playersMapping;

    APWarsCollectibles private collectibles;

    uint256 public emergencyWithdralInterval;

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

    /// @notice The war information.
    /// @dev See the WarInfo struct.
    WarInfo public war;

    /// @notice The external random source hash.
    bytes32 public externalRandomSourceHashes;

    /// @notice It stores the current stage per war.
    WarStage public warStage;

    /// @notice It stores the first round random parameters generated for a war.
    WarFirstRoundRandomParameters public warFirstRoundRandomParameters;

    /// @notice It stores the second round random parameters generated for a war.
    WarSecondRoundRandomParameters public secondRoundRandomParameters;

    /// @notice It stores the total prize.
    uint256 public totalPrize;

    /// @notice It stores the id of each elixir NFT.
    uint256[] public nfts;

    /// @notice It stores the user alread withdrawn a token.
    mapping(address => mapping(address => bool)) public withdrawn;

    /// @notice It stores the BurnManager address.
    APWarsBurnManagerV2 public burnManager;

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
     * @param team The improved team number.
     * @param initialAttackPower The initial attacker power.
     * @param initialDefensePower The initial defense power.
     * @param improvementAttackPower The calculated attack improvement.
     * @param improvementDefensePower The calculated defense improvement.
     * @param newAttackPower The attack power after improvement.
     * @param newDefensePower The defense power after improvement.
     */
    event TroopImprovement(
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
     * @param attackerTeam The attacker team number.
     * @param defenderTeam The defender team number.
     * @param attackerCasualty The percentage of attacker casualty.
     * @param defenderCasualty The percentage of defender casualty.
     * @param attackerLuck The percentage of attacker luck.
     * @param defenderLuck The percentage of defender luck.
     * @param isBadLuck Specifies if is a bad luck (negative luck).
     */
    event FirstRoundRandomParameters(
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
     * @param unlockedPrize The percentual of the unlocked prize.
     * @param casualty The casualty in the second round.
     */
    event SecondRoundRandomParameters(uint256 unlockedPrize, uint256 casualty);

    /**
     * @notice Fired when the contract calculates the team losses.
     * @param team The team number.
     * @param isAttacker Specifies if the team is the attacker.
     * @param initialPower Specifies the team's initial power.
     * @param power Specifies the team's final power.
     * @param otherTeamPower Specifies the other team's final power.
     * @param losses Specifies the losses percentage.
     */
    event TeamLosses(
        uint256 indexed team,
        bool indexed isAttacker,
        uint256 initialPower,
        uint256 power,
        uint256 otherTeamPower,
        uint256 losses
    );

    /**
     * @notice Fired when the contract owner finishes a round.
     * @param sender Transaction sender.
     * @param externalRandomSource The revealed external random source.
     * @param winner The winner team.
     */
    event RoundFinished(
        uint256 indexed round,
        address sender,
        bytes32 externalRandomSource,
        uint256 winner,
        uint256 winnerLosses
    );

    /**
     * @notice Fired when an user request to withdraw the amount after a war.
     * @param player The player address.
     * @param tokenAddress The unit token address.
     * @param deposit The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event Withdraw(
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
     * @param player The player address.
     * @param tokenAddress The token prize address.
     * @param totalPower The team total power.
     * @param userTotalPower The user total power (to calculate the user share in the prize).
     * @param userShare The deposited amount.
     * @param burned The amount burned due to war losses.
     * @param net The net amount sent to user.
     */
    event PrizeWithdraw(
        address indexed player,
        address indexed tokenAddress,
        uint256 totalPower,
        uint256 userTotalPower,
        uint256 userShare,
        uint256 burned,
        uint256 net
    );

    constructor() {
        emergencyWithdralInterval = block.timestamp + 15 days;
    }

    /**
     * @notice It configures a the war with addresses and initial values.
     * @param _tokenPrize The token prize address (wGOLD contract).
     * @param _burnManager The BurnManager address.
     * @param _teamA Team A token addresses.
     * @param _teamB Team B token addresses.
     * @param _collectibles Collectibles address.
     * @param _nfts NFTs ids. Indexes 0-2 are the exlixirs ID, index 3 the Arcane's Book Id and index 4 Beloved Hater.
     */
    function setup(
        IAPWarsBaseToken _tokenPrize,
        APWarsBurnManagerV2 _burnManager,
        IAPWarsUnit[] calldata _teamA,
        IAPWarsUnit[] calldata _teamB,
        APWarsCollectibles _collectibles,
        uint256[] calldata _nfts
    ) public onlyOwner {
        collectibles = _collectibles;
        burnManager = _burnManager;
        nfts = _nfts;

        tokenPrize = address(_tokenPrize);

        delete allowedTeamTokenAddresses[TEAM_A];
        delete allowedTeamTokenAddresses[TEAM_B];

        for (uint256 i = 0; i < _teamA.length; i++) {
            teams[address(_teamA[i])] = TEAM_A;
            allowedTeamTokenAddresses[TEAM_A].push(address(_teamA[i]));
        }

        for (uint256 i = 0; i < _teamB.length; i++) {
            teams[address(_teamB[i])] = TEAM_B;
            allowedTeamTokenAddresses[TEAM_B].push(address(_teamB[i]));
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
        war = WarInfo(_name, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0);
        warStage = WarStage.FIRST_ROUND;
        externalRandomSourceHashes = _externalRandomSourceHash;
    }

    /**
     * @notice It returns the player address by index.
     * @return The player address.
     */
    function getPlayerAddress(uint256 index) public view returns (address) {
        return players[index];
    }

    /**
     * @notice It returns how many players joined the war.
     * @return The players length.
     */
    function getPlayerLength() public view returns (uint256) {
        return players.length;
    }

    /**
     * @notice The way to send troops to war is depositing unit tokens, each unit token has attack and defense power and by
     * depositing the user is inscreasing the team power. Both sides do not for if they will attack or defense, so the rigth way
     * to fish this war is send the maximum amount of troops!
     * This method needs to receive the approval from the unit token contract to transfer the specified amount.
     * If the war is in the second round only winners can send more troops to collect more gold.
     * @param _unit Unit token address.
     * @param _amount How many troops the user is sending to war.
     */
    function deposit(IAPWarsUnit _unit, uint256 _amount) public nonReentrant {
        address tokenAddress = address(_unit);

        //identifying if the token is part from the TEAM_A or TEAM_B;
        uint256 team = teams[tokenAddress];
        WarStage stage = warStage;

        require(stage == WarStage.FIRST_ROUND, "War:DEPOSIT_IS_BLOCKED");

        //transfering the amount to this contract and increase the user deposit amount
        _unit.transferFrom(msg.sender, address(this), _amount);
        depositsByPlayer[tokenAddress][msg.sender] = depositsByPlayer[
            tokenAddress
        ][msg.sender]
            .add(_amount);
        depositsByToken[tokenAddress] = depositsByToken[tokenAddress].add(
            _amount
        );

        //getting the total power (attack and defense)
        uint256 troopAttackPower = _unit.getAttackPower().mul(_amount);
        uint256 troopDefensePower = _unit.getDefensePower().mul(_amount);

        //if the user has the Beloved Hate NFT it will increase the attack power in 1%
        uint256 belovedHaterImprovement = 0;
        if (collectibles.balanceOf(msg.sender, nfts[4]) > 0) {
            belovedHaterImprovement = troopAttackPower.mul(ONE_PERCENT).div(
                ONE_HUNDRED_PERCENT
            );

            troopAttackPower = troopAttackPower.add(belovedHaterImprovement);
        }

        //updating attack and defense powers
        attackPowerByAddress[team][msg.sender] = attackPowerByAddress[team][
            msg.sender
        ]
            .add(troopAttackPower);
        attackPower[team] = attackPower[team].add(troopAttackPower);
        defensePowerByAddress[team][msg.sender] = defensePowerByAddress[team][
            msg.sender
        ]
            .add(troopDefensePower);
        defensePower[team] = defensePower[team].add(troopDefensePower);

        if (!playersMapping[msg.sender]) {
            playersMapping[msg.sender] = true;
            players.push(msg.sender);
        }

        emit NewDeposit(
            msg.sender,
            tokenAddress,
            team,
            _amount,
            troopAttackPower,
            troopDefensePower,
            attackPower[team],
            defensePower[team],
            belovedHaterImprovement
        );
    }

    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    /**
     * @notice It calculates the random parameters from the revealed externam random source.
     * @dev See the docs to understand how it works. It is not so hard, but be guided by examples is a better way.
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function _defineFirstRoundRandomParameters(bytes32 _externalRandomSource)
        internal
    {
        uint256 salt = 0;

        uint256 randomTeamSource =
            random(_externalRandomSource, salt, ONE_HUNDRED_PERCENT);
        bool isTeamA = randomTeamSource > ONE_HUNDRED_PERCENT / 2;

        war.attackerTeam = isTeamA ? TEAM_A : TEAM_B;
        war.defenderTeam = !isTeamA ? TEAM_A : TEAM_B;

        salt = salt.add(randomTeamSource);

        war.attackerCasualty = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT
        );
        salt = salt.add(war.attackerCasualty);
        war.defenderCasualty = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT
        );
        salt = salt.add(war.defenderCasualty);
        war.attackerLuck = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.attackerLuck);
        war.defenderLuck = random(
            _externalRandomSource,
            salt,
            ONE_HUNDRED_PERCENT / 5
        );
        salt = salt.add(war.defenderLuck);

        uint256 randomBadLuckSource =
            random(_externalRandomSource, salt, ONE_HUNDRED_PERCENT);

        war.isBadLuck = randomBadLuckSource > ONE_HUNDRED_PERCENT / 2;

        warFirstRoundRandomParameters = WarFirstRoundRandomParameters(
            randomTeamSource,
            war.attackerCasualty,
            war.defenderCasualty,
            war.attackerLuck,
            war.defenderLuck,
            randomBadLuckSource
        );

        emit FirstRoundRandomParameters(
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
     */
    function _calculateTroopImprovement() internal {
        uint256 attackImprovement = 0;
        uint256 defenseImprovement = 0;

        uint256 initialAttackePower = attackPower[TEAM_A];
        uint256 initialDefensePower = defensePower[TEAM_A];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_A].length; i++) {
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_A][i]);
            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[TEAM_A] = attackImprovement;

                defenseImprovement = defensePower[TEAM_A]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                defensePower[TEAM_A] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            TEAM_A,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[TEAM_A],
            defensePower[TEAM_A]
        );

        initialAttackePower = attackPower[TEAM_B];
        initialDefensePower = defensePower[TEAM_B];

        for (uint256 i = 0; i < allowedTeamTokenAddresses[TEAM_B].length; i++) {
            IAPWarsUnit unit =
                IAPWarsUnit(allowedTeamTokenAddresses[TEAM_B][i]);

            uint256 balance = unit.balanceOf(address(this));

            if (unit.getTroopImproveFactor() > 0 && balance > 0) {
                attackImprovement = attackPower[TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                attackPower[TEAM_B] = attackImprovement;

                defenseImprovement = defensePower[TEAM_B]
                    .mul(unit.getTroopImproveFactor())
                    .div(ONE_HUNDRED_PERCENT)
                    .mul(balance.div(ONE));

                defensePower[TEAM_B] = defenseImprovement;
            }
        }

        emit TroopImprovement(
            TEAM_B,
            initialAttackePower,
            initialDefensePower,
            attackImprovement,
            defenseImprovement,
            attackPower[TEAM_B],
            defensePower[TEAM_B]
        );
    }

    /**
     * @notice It calculates the luck of a team. The luck of a team is the same amount of badluck to another.
     *         This function uses the pre-calculated random luck percentual.
     */
    function _calculateLuckImpact() internal {
        uint256 initialAttackPower = attackPower[war.attackerTeam];
        uint256 initialDefensePower = defensePower[war.defenderTeam];

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
     */
    function _calculateMoraleImpact() internal {
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
     */
    function _calculateLosses() internal {
        uint256 initialAttackPower = attackPower[war.attackerTeam];
        uint256 initialDefensePower = defensePower[war.defenderTeam];

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
            war.attackerTeam,
            true,
            initialAttackPower,
            war.finalAttackPower,
            totalPower,
            war.percAttackerLosses
        );

        emit TeamLosses(
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
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishFirstRound(bytes32 _externalRandomSource) public onlyOwner {
        _calculateTroopImprovement();
        _defineFirstRoundRandomParameters(_externalRandomSource);
        _calculateLuckImpact();

        // if there is no other side there is no morale impact
        if (war.finalAttackPower > 0 && war.finalDefensePower > 0) {
            _calculateMoraleImpact();
        }
        _calculateLosses();

        warStage = WarStage.SECOND_ROUND;

        emit RoundFinished(
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
     * @param _externalRandomSource The revealed origin external random source registered on the war creation.
     */
    function finishSecondRound(bytes32 _externalRandomSource) public onlyOwner {
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenPrize);

        secondRoundRandomParameters.unlockedPrize = random(
            _externalRandomSource,
            0,
            ONE_HUNDRED_PERCENT
        );
        secondRoundRandomParameters.casualty = random(
            _externalRandomSource,
            secondRoundRandomParameters.unlockedPrize,
            ONE_HUNDRED_PERCENT
        );

        warStage = WarStage.FINISHED;
        totalPrize = token.balanceOf(address(this));

        //calculating the new losses after the second round
        uint256 losses =
            war.winner == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;
        uint256 newLosses =
            losses
                .mul(secondRoundRandomParameters.casualty)
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
            secondRoundRandomParameters.unlockedPrize,
            secondRoundRandomParameters.casualty
        );
        emit RoundFinished(
            2,
            msg.sender,
            _externalRandomSource,
            war.winner,
            newLosses
        );
    }

    function getPlayerInfo(address[] calldata _tokenAddresses, address _player)
        public
        view
        returns (
            uint256 depositAmount,
            uint256 totalAttackPowerTeamA,
            uint256 totalAttackPowerTeamB,
            uint256 totalDefensePowerTeamA,
            uint256 totalDefensePowerTeamB
        )
    {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            depositAmount = depositAmount.add(
                depositsByPlayer[_tokenAddresses[i]][_player]
            );
        }

        totalAttackPowerTeamA = attackPowerByAddress[TEAM_A][_player];
        totalAttackPowerTeamB = attackPowerByAddress[TEAM_B][_player];
        totalDefensePowerTeamA = defensePowerByAddress[TEAM_A][_player];
        totalDefensePowerTeamB = defensePowerByAddress[TEAM_B][_player];
    }

    function getWarInfo(uint256 _team, address[] calldata _tokenAddresses)
        public
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalAttackPower,
            uint256 totalDefensePower,
            address warTokenPrize,
            APWarsCollectibles warCollectibles
        )
    {
        address tokenAddress = address(0);

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddress = _tokenAddresses[i];
            totalDepositAmount = totalDepositAmount.add(
                depositsByToken[tokenAddress]
            );
        }

        totalAttackPower = attackPower[_team];
        totalDefensePower = defensePower[_team];
        warTokenPrize = tokenPrize;
        warCollectibles = collectibles;
    }

    /**
     * @notice It withdraws the remaining amount of a unit token after the war. This function get the troop back to home.
     * @param _unit Unit token address.
     */
    function withdraw(IAPWarsUnit _unit) public nonReentrant {
        address tokenAddress = address(_unit);

        require(address(_unit) != tokenPrize, "War:INVALID_TOKEN_ADDRESS");

        require(
            !withdrawn[msg.sender][address(_unit)],
            "War:ALREADY_WITHDRAWN"
        );

        require(
            teams[tokenAddress] == TEAM_A || teams[tokenAddress] == TEAM_B,
            "War:INVALID_TOKEN_ADDRESS"
        );
        require(
            warStage == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAW"
        );

        uint256 team = teams[tokenAddress];
        uint256 depositAmount = depositsByPlayer[tokenAddress][msg.sender];

        uint256 toBurnPerc =
            team == war.attackerTeam
                ? war.percAttackerLosses
                : war.percDefenderLosses;

        uint256 amountToSave = 0;

        if (_unit.getTroopImproveFactor() > 0) {
            if (collectibles.balanceOf(msg.sender, nfts[3]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        } else {
            if (collectibles.balanceOf(msg.sender, nfts[0]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, nfts[1]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT + FIVE_PERCENT);
            }

            if (collectibles.balanceOf(msg.sender, nfts[2]) > 0) {
                amountToSave = amountToSave.add(TEN_PERCENT * 2 + FIVE_PERCENT);
            }
        }

        uint256 originalToBurnPerc = toBurnPerc;

        if (amountToSave > toBurnPerc) {
            toBurnPerc = 0;
        } else {
            toBurnPerc = toBurnPerc.sub(amountToSave);
        }

        uint256 amountToBurn =
            depositAmount.mul(toBurnPerc).div(ONE_HUNDRED_PERCENT);
        uint256 net = depositAmount - amountToBurn;

        _unit.transfer(address(burnManager), amountToBurn);
        burnManager.burn(address(_unit));

        //avoinding rounding errors to the last user
        if (_unit.balanceOf(address(this)) < net) {
            _unit.transfer(msg.sender, _unit.balanceOf(address(this)));
        } else {
            _unit.transfer(msg.sender, net);
        }

        withdrawn[msg.sender][address(_unit)] = true;

        emit Withdraw(
            msg.sender,
            tokenAddress,
            depositAmount,
            originalToBurnPerc,
            amountToSave,
            amountToBurn,
            net
        );
    }

    /**
     * @notice It returns the total prize locked when the war was finished or the current balance if the war is running.
     */
    function getTotalPrize() public view returns (uint256) {
        return
            totalPrize == 0
                ? IAPWarsBaseToken(tokenPrize).balanceOf(address(this))
                : totalPrize;
    }

    //TODO: Check if the user can run this method
    /**
     * @notice It withdraws the unlocked prize and burns the locked prize for each user.
     *         The total prize is the token prize total balance when the war is finisehd.
     *         The user share corresponds to the proportion of user total power and the the team
     *         total power.
     */
    function withdrawPrize() public nonReentrant {
        address tokenAddress = tokenPrize;
        IAPWarsBaseToken token = IAPWarsBaseToken(tokenAddress);

        require(
            !withdrawn[msg.sender][address(tokenAddress)],
            "War:ALREADY_WITHDRAWN"
        );

        require(
            warStage == WarStage.FINISHED,
            "War:INVALID_WAR_STAGE_TO_WITHDRAL_PRIZE"
        );

        bool isAttacker = war.attackerTeam == war.winner;
        uint256 teamTotalPower =
            isAttacker ? attackPower[war.winner] : defensePower[war.winner];
        uint256 userTotalPower =
            isAttacker
                ? attackPowerByAddress[war.winner][msg.sender]
                : defensePowerByAddress[war.winner][msg.sender];

        uint256 userShare =
            userTotalPower.mul(ONE_HUNDRED_PERCENT).div(teamTotalPower);
        uint256 userPrize = totalPrize.mul(userShare).div(ONE_HUNDRED_PERCENT);
        uint256 amountToBurn =
            userPrize.mul(secondRoundRandomParameters.unlockedPrize).div(
                ONE_HUNDRED_PERCENT
            );
        uint256 net = userPrize - amountToBurn;

        token.transfer(address(burnManager), amountToBurn);
        burnManager.burn(address(token));

        //avoinding rounding errors to the last user
        if (token.balanceOf(address(this)) < net) {
            token.transfer(msg.sender, token.balanceOf(address(this)));
        } else {
            token.transfer(msg.sender, net);
        }

        withdrawn[msg.sender][address(tokenAddress)] = true;

        emit PrizeWithdraw(
            msg.sender,
            tokenAddress,
            teamTotalPower,
            userTotalPower,
            userShare,
            amountToBurn,
            net
        );
    }

    function emergencyWithdraw(IAPWarsBaseToken _token, uint256 _amount)
        public
        onlyOwner
    {
        require(
            block.timestamp > emergencyWithdralInterval,
            "War:NOT_ALLOWED_YET"
        );

        _token.transfer(msg.sender, _amount);
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
     * @param _externalRandomSource The original external random source.
     * @param _salt A salt to generate random numbers using the same external random source.
     * @param _maxNumber The max number to be generated, used to create a range of random number.
     * @return Then computed pseudo random number.
     */
    function random(
        bytes32 _externalRandomSource,
        uint256 _salt,
        uint256 _maxNumber
    ) public view returns (uint256) {
        bytes32 hash = hashExternalRandomSource(_externalRandomSource);

        require(
            hash == externalRandomSourceHashes,
            "War:INVALID_EXTERNAL_RANDOM_SOURCE"
        );

        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        bytes32 _structHash =
            keccak256(
                abi.encode(_blockhash, gasLeft, _salt, _externalRandomSource)
            );
        uint256 _randomNumber = uint256(_structHash);

        assembly {
            _randomNumber := add(mod(_randomNumber, _maxNumber), 1)
        }

        return _randomNumber;
    }
}
