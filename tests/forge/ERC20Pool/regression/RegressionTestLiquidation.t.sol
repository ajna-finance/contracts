// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import { LiquidationInvariants } from "../invariants/LiquidationInvariants.t.sol";

contract RegressionTestLiquidation is LiquidationInvariants { 

    function setUp() public override { 
        super.setUp();
    }

    function test_regression_quote_token() external {
        _liquidationPoolHandler.addQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639932, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_arithmetic_overflow() external {
        _liquidationPoolHandler.kickAuction(128942392769655840156268259377571235707684499808935108685525899532745, 9654010200996517229486923829624352823010316518405842367464881, 135622574118732106350824249104903);
        _liquidationPoolHandler.addQuoteToken(3487, 871, 1654);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_bucket_take_lps() external {
        _liquidationPoolHandler.removeQuoteToken(7033457611004217223271238592369692530886316746601644, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _liquidationPoolHandler.addQuoteToken(1, 20033186019073, 1);
        _liquidationPoolHandler.bucketTake(0, 0, false, 2876997751);

        invariant_Lps_B1_B4();
    }

    function test_regression_interest_rate() external {
        _liquidationPoolHandler.bucketTake(18065045387666484532028539614323078235438354477798625297386607289, 14629545458306, true, 1738460279262663206365845078188769);

        invariant_interest_rate_I1();
    }

    function test_regression_incorrect_no_of_borrowers() external {
        _liquidationPoolHandler.moveQuoteToken(18178450611611937161732340858718395124120481640398450530303803, 0, 93537843531612826457318744802930982491, 15596313608676556633725998020226886686244513);
        _liquidationPoolHandler.addCollateral(2208149704044082902772911545020934265, 340235628931125711729099234105522626267587665393753030264689924088, 2997844437211835697043096396926932785920355866486893005710984415271);
        _liquidationPoolHandler.moveQuoteToken(56944009718062971164908977784993293, 737882204379007468599822110965749781465, 1488100463155679769353095066686506252, 11960033727528802202227468733333727294);
        _liquidationPoolHandler.moveQuoteToken(47205392335275917691737183012282140599753693978176314740917, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 164043848691337333691028718232);
        _liquidationPoolHandler.kickAuction(184206711567329609153924955630229148705869686378631519380021040314, 78351, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _liquidationPoolHandler.kickAuction(3, 199726916764352560035199423206927461876998880387108455962754538835220966553, 3);
        _liquidationPoolHandler.removeQuoteToken(999999991828440064944955196599190431639924811, 2781559202773230142346489450532860130, 3000000005240421579956496007310960085855569344);
        _liquidationPoolHandler.pullCollateral(48768502867710912107594904694036421700, 275047566877984818806178837359260100);
        _liquidationPoolHandler.bucketTake(2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, false, 8154570107391684241724530527782571978369827827856399749867491880);
        _liquidationPoolHandler.removeCollateral(43733538637150108518954934566131291302796656384802361118757432084573, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _liquidationPoolHandler.addQuoteToken(1, 2, 2);
        _liquidationPoolHandler.repayDebt(647805461526201272, 0);
        _liquidationPoolHandler.kickAuction(1019259585194528028904148545812353964867041444572537077023497678982801, 58796345025472936970320, 131319002678489819637546489086162345032717166507611595521);
        _liquidationPoolHandler.moveQuoteToken(2, 2, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _liquidationPoolHandler.moveQuoteToken(6164937621056362865643346803975636714, 4, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 315548939052682258);
        _liquidationPoolHandler.repayDebt(2987067394366841692658, 170206016570563384086766968869520628);
        _liquidationPoolHandler.pledgeCollateral(3558446182295495994762049031, 0);
        _liquidationPoolHandler.drawDebt(4525700839008283200312069904720925039, 3000000000753374912785563581177665475703155339);
        _liquidationPoolHandler.kickAuction(1, 3559779948348618822016735773117619950447774, 218801416747720);
        _liquidationPoolHandler.addQuoteToken(1469716416900282992357252011629715552, 13037214114647887147246343731476169800, 984665637618013480616943810604306792);
        _liquidationPoolHandler.pullCollateral(438961419917818200942534689247815826455600131, 64633474453314038763068322072915580384442279897841981);

        invariant_auctions_A3_A4();
    }

    // test was failing due to deposit time update even if kicker lp reward is 0.
    // resolved with PR: https://github.com/ajna-finance/contracts/pull/674
    function test_regression_bucket_deposit_time() external {
        _liquidationPoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 2079356830967144967054363629631641573895835179323954988585146991431, 233005625580787863707944);
        _liquidationPoolHandler.bucketTake(21616, 1047473235778002354, false, 1062098588952039043823357);
        _liquidationPoolHandler.bucketTake(1673497622984405133414814181152, 94526073941076989987362055170246, false, 1462);

        invariant_Bucket_deposit_time_B5();
    }

    function test_regression_transfer_taker_lps_bucket_deposit_time() external {
        _liquidationPoolHandler.settleAuction(3637866246331061119113494215, 0, 6163485280468362485998190762304829820899757798629605592174295845105660515);
        _liquidationPoolHandler.transferLps(1610, 1000000000018496758270674070884, 168395863093969200027183125335, 2799494920515362640996160058);
        _liquidationPoolHandler.bucketTake(0, 10619296457595008969473693936299982020664977642271808785891719078511288, true, 1681500683437506364426133778273769573223975355182845498494263153646356302);

        invariant_Bucket_deposit_time_B5();
    }

    function test_regression_invariant_fenwick_depositAtIndex_F1() external {
        _liquidationPoolHandler.moveQuoteToken(4058, 2725046678043704335543997294802562, 16226066, 4284);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_fenwick_prefixSumIndex_F4() external {
        _liquidationPoolHandler.bucketTake(2164, 2818, false, 1801);
        _liquidationPoolHandler.transferLps(2, 1, 7, 106103589728450765);
        _liquidationPoolHandler.kickAuction(14478, 6462, 3748);

        invariant_fenwick_prefixSumIndex_F4();
    }
}
