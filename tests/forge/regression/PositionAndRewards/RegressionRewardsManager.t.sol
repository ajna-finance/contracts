
pragma solidity 0.8.14;

import { RewardsInvariants } from "../../invariants/PositionsAndRewards/RewardsInvariants.t.sol";

contract RegressionRewardsManager is RewardsInvariants {

    function setUp() public override { 
        super.setUp();
    }


    function test_regression_rewards_PM1_1() public {
        _rewardsHandler.unstake(156983341, 3, 1057, 627477641256361);
        _rewardsHandler.settleAuction(2108881198342615861856429474, 922394580216134598, 4169158839, 1000000019773478651);
        invariant_positions_PM1_PM2();
    }

    function test_regression_rewards_PM1_2() public {
        _rewardsHandler.addCollateral(378299828523348996450409252968204856717337200844620995950755116109442848, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 52986329559447389847739820276326448003115507778858588690614563138365, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.memorializePositions(2386297678015684371711534521507, 1, 2015255596877246640, 0);
        _rewardsHandler.moveLiquidity(999999999999999999999999999999999999999542348, 2634, 6160, 4579, 74058);
        invariant_positions_PM1_PM2();
    }

    function test_regression_rewards_PM1_3() public {
        _rewardsHandler.memorializePositions(1072697513541617411598352761547948569235246260453338, 49598781763341098132796575116941537, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 59786055813720421827623480119157950185156928336);
        _rewardsHandler.drawDebt(71602122977707056985766204553433920464603022469065, 0, 3);
        _rewardsHandler.settleAuction(1533, 6028992255037431023, 999999999999998827363045226813101730497689206, 3712);
        _rewardsHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639935, 14721144691130718757631011689447950991492275176685060291564256, false, 136782600565674582447300799997512602488616407787063657498, 12104321153503350510632448265168933687786653851546540372949180052575211);
        _rewardsHandler.unstake(5219408520630054730985988951364206956803005171136246340104521696738150, 2, 0, 7051491938468651247212916289972038814809873);
        _rewardsHandler.settleAuction(0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 120615857050623137463512130550262626813346106);
        invariant_positions_PM1_PM2();
    }

    function test_regression_rewards_PM1_4() public {
        _rewardsHandler.memorializePositions(1585983020218223508466618588295, 2, 242, 10522957038296280790589164493000706993449273065060811143889771);
        _rewardsHandler.moveStakedLiquidity(124495881328, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 19303000352555, 580055590177, 2);
        invariant_positions_PM1_PM2();
    }

    function test_regression_rewards_PM1_5() public {
        _rewardsHandler.moveLiquidity(832921267658491751933537549, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 62241022956197145532, 1165012150, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 108613063553696015935192567274231711586207468226993603118670370534031542, 2, 1);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 3);
        _rewardsHandler.settleAuction(1694548149298356876485941302354, 9052, 1444291546717740702970, 1303240033616582679504132393648);
        _rewardsHandler.burn(0, 707668523430171576399252973860135329463494151705, 13231138491987546580, 3);
        /* Logs before moveStakedLiquidity
            Position Manager at bucket 2572:
            Lps - 0
            depositTime - 0

            Position Manager at bucket 2571:
            Lps - 0 considering bucket is bankrupt
            depositTime - 1707801700

            Bucket 2571 bankrupty time in pool - 1707752026

            TokenId - 1 positions:
            - bucket 2571:
              Actual Lps - 62241022956197145532
              Lps after considering bankrupty time - 0
              depositTime - 1672404972

        */
        _rewardsHandler.moveStakedLiquidity(115792089237316195423570985008687907853269984665640564039457584007913129639933, 9951345024297122146792989820571693988360874292538858793, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 2);
        /* Logs after moveStakedLiquidity - Liquidity moved from bucket 2572 to 2571 for tokenId - 3
            Position Manager at bucket 2571:
            LPs - 13189459982951652473123372396
            depositTime - 1707801700

            Bucket 2571 bankrupty time in pool - 1707752026

            TokenId - 1 positions:
            - bucket 2571:
              Actual Lps - 62241022956197145532
              Lps after considering bankrupty time - 0
              depositTime - 1672404972
              
            TokenId - 3 positions:
            - bucket 2571
              Actual Lps - 13189459982951652473123372396
              Lps after considering bankrupty time - 0
              depositTime - 1689933378
        */
        invariant_positions_PM1_PM2();
    }

    function test_regression_rewards_RW1() public {
        invariant_rewards_RW1();
    }

    function test_regression_evm_revert_1() public {
        _rewardsHandler.moveStakedLiquidity(22217, 22071, 8350, 6712, 2545);
        _rewardsHandler.kickAuction(4927, 15287, 1672621391, 7794);
        _rewardsHandler.removeQuoteToken(0, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 3);
        _rewardsHandler.takeAuction(2575, 5650, 2711, 12004413);
        _rewardsHandler.mint(1515215594322469882937526919173, 2864);
        _rewardsHandler.removeQuoteToken(11445, 2303142144561970723486793685729, 3879, 1008905021187010892);
        _rewardsHandler.redeemPositions(23630504830242022841459200705989645184404322170375013590678501625107, 1, 282473030835977356124316597209309127812, 0);
        _rewardsHandler.redeemPositions(4829, 7399, 20165, 19797);
        _rewardsHandler.addQuoteToken(8330901901683684346410, 1944730599598704240629, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _rewardsHandler.mint(52483, 375);
        _rewardsHandler.removeQuoteToken(242161003333451991910682, 833804465517702, 0, 153306087017);
        _rewardsHandler.claimRewards(5460042422485935527540305190804180316252530934172557782973004, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 2317020199583405169185090105199, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function test_regression_evm_revert_2() public {
        _rewardsHandler.redeemPositions(535, 10526, 16402, 90638196);
        _rewardsHandler.moveQuoteToken(3, 3, 3665933105380066469, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 35609320936341689682324970775);
        _rewardsHandler.kickWithDeposit(65195123838887638071598468995195715179071041842210505440218069543269527898574, 1428, 1550);
        _rewardsHandler.updateExchangeRate(3324, 3433, 385);
        _rewardsHandler.moveStakedLiquidity(46838334839030508021621535975748471432135882830, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 3475914340014947863646050, 2929134793936453261729380387854064624771476760912, 1);
        _rewardsHandler.removeQuoteToken(487993211956248337274085963929265840000354071708865988088685578811819, 8714694397591072960002001972219030782403253520, 0, 0);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3, 3, 0);
        _rewardsHandler.addQuoteToken(8049702985159192133654841011926250176578891096284667148191654768576101, 420390974052856985135062265979816823871512, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 6168047604119363323178237637165700555180739052007127817776433423995137133826);
        _rewardsHandler.pledgeCollateral(38623724134600076305519407, 1, 42313782903);
        _rewardsHandler.takeAuction(2520288506, 56779, 10626, 2578);
        _rewardsHandler.updateExchangeRate(2374, 3180, 11271);
        _rewardsHandler.moveQuoteToken(3, 84452381279, 65209096465360247728023547148755401892588275436, 1, 97710781974409185143365462469280072552935020234615584635942788);
        _rewardsHandler.claimRewards(4219, 7299, 3792253, 3829);
    }

    function test_regression_evm_revert_burnedInEpochZero() external {
        _rewardsHandler.takeAuction(7657762660104020786102326341030666744203129169035726688092178, 1, 3, 63603943629412590405183648739466756021204);
        _rewardsHandler.moveLiquidity(853498184631967766239539459019, 860800972267934599, 2712933514310088838415608172991, 672432889047616138980078995830, 1940131010529342263123392466824);
        _rewardsHandler.repayDebt(115792089237316195423570985008687907853269984665640564039457584007913129639933, 427572220473655037333866875012561018809807470070214697627941860984, 44890261877119855592686274106685080718432502924958626579185298373762938186596);
        // stake ( update ex rates -> stake ) -> kick res -> take res -> unstake( update ex rates -> unstake)
        // epoch: 1
        // burned 27895
        _rewardsHandler.unstake(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1);
        _rewardsHandler.pledgeCollateral(1, 0, 2);
        _rewardsHandler.pledgeCollateral(46380480507328, 10, 1);
        // stake ( update ex rates -> stake ) -> kick res -> take res -> unstake( update ex rates -> unstake)
        // epoch: 2
        // burned 27895
        _rewardsHandler.claimRewards(1852732090424016924140170274064383911484, 183940675308906, 0, 53861119148520095956903865568282398357460507464813555898544376318790433189);
        _rewardsHandler.takeReserves(115792089237316195423570985008687907853269984665640564039457584007913129639932, 395769107397432386894162390920154234120, 10606604808645482457593038172768629927057694502686);
        _rewardsHandler.removeQuoteToken(2, 1, 2192625645230692453890585257984624461888, 6660232197673667038115249964);
        // stake ( update ex rates -> stake ) -> kick res -> take res -> unstake( update ex rates -> unstake)
        // test was failing in the stake action that occured in _preUnstake()
        // * totalBurnedInEpoch was returning 0 since no burn happened between unstake in claimRewards ^^ and the stake in _preUnstake
        // * caused underflow since rewardsCap = 0 in this edge case
        // * fixed by adding a check in updateBucketExchangeRates() to not evaluate rewardsCap unless totalBurnedInEpoch > 0 
        _rewardsHandler.unstake(10754921060610721338628656060623251463708357833056948746687720475, 2630, 3678, 47729066275298389217682475444047844926190);
    }

}