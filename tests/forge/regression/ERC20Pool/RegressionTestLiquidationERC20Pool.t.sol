// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import { LiquidationERC20PoolInvariants } from "../../invariants/ERC20Pool/LiquidationERC20PoolInvariants.t.sol";

contract RegressionTestLiquidationERC20Pool is LiquidationERC20PoolInvariants { 

    function setUp() public override { 
        super.setUp();
    }

    function test_regression_quote_token() external {
        _liquidationERC20PoolHandler.addQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639932, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_arithmetic_overflow() external {
        _liquidationERC20PoolHandler.kickAuction(128942392769655840156268259377571235707684499808935108685525899532745, 9654010200996517229486923829624352823010316518405842367464881, 135622574118732106350824249104903, 0);
        _liquidationERC20PoolHandler.addQuoteToken(3487, 871, 1654, 0);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_bucket_take_lps() external {
        _liquidationERC20PoolHandler.removeQuoteToken(7033457611004217223271238592369692530886316746601644, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.addQuoteToken(1, 20033186019073, 1, 0);
        _liquidationERC20PoolHandler.bucketTake(0, 0, false, 2876997751, 0);

        invariant_Lps_B1();
    }

    function test_regression_interest_rate() external {
        _liquidationERC20PoolHandler.bucketTake(18065045387666484532028539614323078235438354477798625297386607289, 14629545458306, true, 1738460279262663206365845078188769, 0);

        invariant_interest_rate_I1();
    }

    function test_regression_incorrect_no_of_borrowers() external {
        _liquidationERC20PoolHandler.moveQuoteToken(18178450611611937161732340858718395124120481640398450530303803, 0, 93537843531612826457318744802930982491, 15596313608676556633725998020226886686244513, 0);
        _liquidationERC20PoolHandler.addCollateral(2208149704044082902772911545020934265, 340235628931125711729099234105522626267587665393753030264689924088, 2997844437211835697043096396926932785920355866486893005710984415271, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(56944009718062971164908977784993293, 737882204379007468599822110965749781465, 1488100463155679769353095066686506252, 11960033727528802202227468733333727294, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(47205392335275917691737183012282140599753693978176314740917, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 164043848691337333691028718232, 0);
        _liquidationERC20PoolHandler.kickAuction(184206711567329609153924955630229148705869686378631519380021040314, 78351, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);
        _liquidationERC20PoolHandler.kickAuction(3, 199726916764352560035199423206927461876998880387108455962754538835220966553, 3, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(999999991828440064944955196599190431639924811, 2781559202773230142346489450532860130, 3000000005240421579956496007310960085855569344, 0);
        _liquidationERC20PoolHandler.pullCollateral(48768502867710912107594904694036421700, 275047566877984818806178837359260100, 0);
        _liquidationERC20PoolHandler.bucketTake(2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, false, 8154570107391684241724530527782571978369827827856399749867491880, 0);
        _liquidationERC20PoolHandler.removeCollateral(43733538637150108518954934566131291302796656384802361118757432084573, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.addQuoteToken(1, 2, 2, 0);
        _liquidationERC20PoolHandler.repayDebt(647805461526201272, 0, 0);
        _liquidationERC20PoolHandler.kickAuction(1019259585194528028904148545812353964867041444572537077023497678982801, 58796345025472936970320, 131319002678489819637546489086162345032717166507611595521, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(2, 2, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(6164937621056362865643346803975636714, 4, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 315548939052682258, 0);
        _liquidationERC20PoolHandler.repayDebt(2987067394366841692658, 170206016570563384086766968869520628, 0);
        _liquidationERC20PoolHandler.pledgeCollateral(3558446182295495994762049031, 0, 0);
        _liquidationERC20PoolHandler.drawDebt(4525700839008283200312069904720925039, 3000000000753374912785563581177665475703155339, 0);
        _liquidationERC20PoolHandler.kickAuction(1, 3559779948348618822016735773117619950447774, 218801416747720, 0);
        _liquidationERC20PoolHandler.addQuoteToken(1469716416900282992357252011629715552, 13037214114647887147246343731476169800, 984665637618013480616943810604306792, 0);
        _liquidationERC20PoolHandler.pullCollateral(438961419917818200942534689247815826455600131, 64633474453314038763068322072915580384442279897841981, 0);

        invariant_auctions_A3_A4();
    }

    // test was failing due to deposit time update even if kicker lp reward is 0.
    // resolved with PR: https://github.com/ajna-finance/contracts/pull/674
    function test_regression_bucket_deposit_time() external {
        _liquidationERC20PoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 2079356830967144967054363629631641573895835179323954988585146991431, 233005625580787863707944, 0);
        _liquidationERC20PoolHandler.bucketTake(21616, 1047473235778002354, false, 1062098588952039043823357, 0);
        _liquidationERC20PoolHandler.bucketTake(1673497622984405133414814181152, 94526073941076989987362055170246, false, 1462, 0);

        invariant_Bucket_deposit_time_B5_B6_B7();
    }

    function test_regression_transfer_taker_lps_bucket_deposit_time() external {
        _liquidationERC20PoolHandler.settleAuction(3637866246331061119113494215, 0, 6163485280468362485998190762304829820899757798629605592174295845105660515, 0);
        _liquidationERC20PoolHandler.transferLps(1610, 1000000000018496758270674070884, 168395863093969200027183125335, 2799494920515362640996160058, 0);
        _liquidationERC20PoolHandler.bucketTake(0, 10619296457595008969473693936299982020664977642271808785891719078511288, true, 1681500683437506364426133778273769573223975355182845498494263153646356302, 0);

        invariant_Bucket_deposit_time_B5_B6_B7();
    }

    function test_regression_invariant_fenwick_depositAtIndex_F1() external {
        _liquidationERC20PoolHandler.moveQuoteToken(4058, 2725046678043704335543997294802562, 16226066, 4284, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_depositKick() external {
        _liquidationERC20PoolHandler.repayDebt(13418, 1160, 0);
        _liquidationERC20PoolHandler.kickWithDeposit(143703836638834364678, 470133688850921941603, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_incorrect_take_2() external {
        _liquidationERC20PoolHandler.kickAuction(13452, 7198, 11328, 0);
        _liquidationERC20PoolHandler.takeAuction(6772, 18720, 6668, 0);
        _liquidationERC20PoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 1666258487708695528254610529989951, 490873240291829575083322665078478117042861655783753, 0);

        invariant_auction_taken_A6();
    }

    function test_regression_invariant_exchange_rate_bucket_take_1() external {
        _liquidationERC20PoolHandler.bucketTake(183325863789657771277097526117552930424549597961930161, 34356261125910963886574176318851973698031483479551872234291832833800, true, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.settleAuction(52219427432114632, 2227306986719506048214107429, 154672727048162052261854237547755782166311596848556350861587480089015671, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(1999999999999999943017433781133248199223345020, 9070, 3519433319314336634208412746825, 0);
        _liquidationERC20PoolHandler.bucketTake(1, 115792089237316195423570985008687907853269984665640564039457584007913129639932, true, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_exchangeRate_R1_R2_R3_R4_R5_R6_R7_R8();
    }

    function test_regression_invariant_exchange_rate_bucket_take_2() external {
        _liquidationERC20PoolHandler.moveQuoteToken(1676213736466301051643762607860, 1344, 2018879446031241805536743752775, 4101, 0);
        _liquidationERC20PoolHandler.settleAuction(186120755740, 2, 59199623628501455128, 0);
        _liquidationERC20PoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 29888344, 0);
        _liquidationERC20PoolHandler.bucketTake(2, 259574184, true, 248534890472324170412180243783490514876275, 0);

        invariant_exchangeRate_R1_R2_R3_R4_R5_R6_R7_R8();
    }

    function test_regression_quote_token_2() external {
        _liquidationERC20PoolHandler.kickAuction(2, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);
        _liquidationERC20PoolHandler.kickAuction(416882035302092397436677640325827, 7379, 253058086367250264569525665396366, 0);
        _liquidationERC20PoolHandler.kickAuction(95740057146806695735694068330212313517380414204596464841344800376300745, 15462030827034, 17811087070659573835739283446817, 0);
        _liquidationERC20PoolHandler.drawDebt(91685640224888183606335500279, 3284161781338443742266950748717011, 0);
        _liquidationERC20PoolHandler.settleAuction(366366807138151363686, 2, 39227118695514892784493088788799944161631371060, 0);

        invariant_quoteTokenBalance_QT1();
    }
    function test_regression_invariant_settle_F1_1() external {
        _liquidationERC20PoolHandler.moveQuoteToken(950842133422927133350903963095785051820046356616, 12698007000117331615195178867, 28462469898, 3434419004419233872687259780980, 0);
        _liquidationERC20PoolHandler.kickAuction(5135, 1752, 6350, 0);
        _liquidationERC20PoolHandler.kickAuction(142699, 4496, 4356, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(1173, 1445, 792325212, 447, 0);
        _liquidationERC20PoolHandler.settleAuction(18308, 3145, 947, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_settle_F1_2() external {
        _liquidationERC20PoolHandler.kickAuction(2, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.takeAuction(166780275301665520376512760721506, 1999999999999999999999999999999999999999997110, 2558901617183837697153566056202031, 0);
        _liquidationERC20PoolHandler.settleAuction(33663580470110889117800273608260215520117498607286850968631643620668, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 376647916322842326327814305437229315203341777076993910570400198695301486, 0);
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 25553353095446, 4576944944764318279058650381557372220045541635899392217977105401448189236370, 0);
        _liquidationERC20PoolHandler.settleAuction(1124188319925967896480196098633929774470471695473649161072280, 2, 1, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_settle_F1_3() external {
        _liquidationERC20PoolHandler.kickAuction(0, 3945558181153878030177, 4183257860938847260218679701589682740098170267658022767240, 0);
        _liquidationERC20PoolHandler.drawDebt(4462122177274869820804814924250, 18446744073709551705, 0);
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 0, 80620507131699866090869932155783811264689, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_settle_F2_1() external {
        _liquidationERC20PoolHandler.kickAuction(2, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.takeAuction(166780275301665520376512760721506, 1999999999999999999999999999999999999999997110, 2558901617183837697153566056202031, 0);
        _liquidationERC20PoolHandler.settleAuction(33663580470110889117800273608260215520117498607286850968631643620668, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 376647916322842326327814305437229315203341777076993910570400198695301486, 0);
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 25553353095446, 4576944944764318279058650381557372220045541635899392217977105401448189236370, 0);
        _liquidationERC20PoolHandler.settleAuction(1124188319925967896480196098633929774470471695473649161072280, 2, 1, 0);

        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_regression_invariant_settle_F2_2() external {
        _liquidationERC20PoolHandler.kickAuction(0, 3945558181153878030177, 4183257860938847260218679701589682740098170267658022767240, 0);
        _liquidationERC20PoolHandler.drawDebt(4462122177274869820804814924250, 18446744073709551705, 0);
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 0, 80620507131699866090869932155783811264689, 0);

        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_regression_invariant_settle_F1_4() external {
        _liquidationERC20PoolHandler.transferLps(1746372434893174899659975954487250106508989011, 2872040610940802546486007303, 3744, 12183, 0);
        _liquidationERC20PoolHandler.takeAuction(1901516289100290457836604652380130002299311381, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 5028305687421043987719245987, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(20368511603587868045081284330731, 489921429793913961108335952, 2190, 0);
        _liquidationERC20PoolHandler.settleAuction(9999999993177259514653978780, 2827825980613220278546740955, 31863690252499070408500382, 0);
        _liquidationERC20PoolHandler.pledgeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639935, 19234747283271867319, 0);
        _liquidationERC20PoolHandler.kickAuction(309236557489990485667503759172591, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_settle_F2_3() external {
        _liquidationERC20PoolHandler.transferLps(1746372434893174899659975954487250106508989011, 2872040610940802546486007303, 3744, 12183, 0);
        _liquidationERC20PoolHandler.takeAuction(1901516289100290457836604652380130002299311381, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 5028305687421043987719245987, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(20368511603587868045081284330731, 489921429793913961108335952, 2190, 0);
        _liquidationERC20PoolHandler.settleAuction(9999999993177259514653978780, 2827825980613220278546740955, 31863690252499070408500382, 0);
        _liquidationERC20PoolHandler.pledgeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639935, 19234747283271867319, 0);
        _liquidationERC20PoolHandler.kickAuction(309236557489990485667503759172591, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_regression_invariant_F3_1() external {
        _liquidationERC20PoolHandler.bucketTake(2935665707632064617811462067363503938617565993411989637, 3, false, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(13019605457845697172279618365097597238993925, 1, 3994854914, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3731592205777443374190, 2, 0);
        _liquidationERC20PoolHandler.takeAuction(3554599780774102176805971372130467746, 140835031537485528703906318530162192, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);
        _liquidationERC20PoolHandler.repayDebt(2692074105646752292572533908391, 1968526964305399089154844418825, 0);
        _liquidationERC20PoolHandler.repayDebt(115792089237316195423570985008687907853269984665640564039457584007913129639935, 4553829, 0);
        _liquidationERC20PoolHandler.bucketTake(3, 115792089237316195423570985008687907853269984665640564039457584007913129639934, true, 0, 0);
        _liquidationERC20PoolHandler.drawDebt(626971501456142588551128155365, 816763288150043968438676, 0);
        _liquidationERC20PoolHandler.pullCollateral(381299861468989210101433912, 999999999999997998400442008957368645662570165, 0);

        invariant_fenwick_bucket_index_F3();
    }

    function test_regression_invariant_F3_2() external {
        _liquidationERC20PoolHandler.moveQuoteToken(15218560385591477289472131001881316985183680418957988997639810360709, 3836, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.kickAuction(1999999999999999999998790777810985454371631707, 730, 1154341805189495974830690344, 0);
        _liquidationERC20PoolHandler.repayDebt(1000015272050180687, 58527020436006764365179004256, 0);
        _liquidationERC20PoolHandler.transferLps(5732870987391656458983245, 12598011738672933544107229257061, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 144447650651692188788340246700695325628363284377395442919761780917, 0);
        _liquidationERC20PoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639933, 3019024412741293564051936001315350655350, true, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);

        invariant_fenwick_bucket_index_F3();
    }

    function test_regression_invariant_F4_1() external {
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 127546297848367334892478587751, 723921922395815633171615243621131242188407029895233162931857565302, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(2, 2, 7361820555, 0);
        _liquidationERC20PoolHandler.takeAuction(85885591922376805486065427318859822458293427950603, 8526258315228761831408142393759013524255378290706574861831877477, 1267004887455971938409309909682740381503049590444968840223, 0);
        _liquidationERC20PoolHandler.drawDebt(663777721413606329209923101072, 946300054291644291801213511570, 0);
        _liquidationERC20PoolHandler.kickAuction(2, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 0);
        _liquidationERC20PoolHandler.addQuoteToken(9360900796482582322800, 694431436637841996793959397509, 553923154643858021986449189292, 0);
        _liquidationERC20PoolHandler.settleAuction(3, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 34469655866078951331675076928366708920312931751567797, 0);
        _liquidationERC20PoolHandler.bucketTake(0, 1, false, 3, 0);
        _liquidationERC20PoolHandler.bucketTake(1190209291225920034207711400729307351194726, 2492241351445208059551299524117408972943752042954, false, 3385052658235853990473420226123930971, 0);
        _liquidationERC20PoolHandler.settleAuction(2693191148227658159823862814074, 44032195641927234172430384447, 2992758194960713897487381207167, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(3, 34308174710409047450205135565, 2, 0);
        _liquidationERC20PoolHandler.takeAuction(235062105582030911119033338, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);

        invariant_fenwick_prefixSumIndex_F4();
    }

    function test_regression_invariant_F4_2() external {
        _liquidationERC20PoolHandler.moveQuoteToken(15218560385591477289472131001881316985183680418957988997639810360709, 3836, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.kickAuction(1999999999999999999998790777810985454371631707, 730, 1154341805189495974830690344, 0);
        _liquidationERC20PoolHandler.repayDebt(1000015272050180687, 58527020436006764365179004256, 0);
        _liquidationERC20PoolHandler.transferLps(5732870987391656458983245, 12598011738672933544107229257061, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 144447650651692188788340246700695325628363284377395442919761780917, 0);
        _liquidationERC20PoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639933, 3019024412741293564051936001315350655350, true, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);

        invariant_fenwick_prefixSumIndex_F4();
    }

    function test_regression_invariant_F4_3() external {
        _liquidationERC20PoolHandler.repayDebt(115792089237316195423570985008687907853269984665640564039457584007913129639934, 88, 0);
        _liquidationERC20PoolHandler.kickWithDeposit(454046303796091226235, 1, 0);
        _liquidationERC20PoolHandler.addQuoteToken(22366532024867500041595597535594488494092956872779970834638, 2056702511, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.takeAuction(7409458575819003489055485098, 19999999999999999999998047232, 160427188541373972791114, 0);
        _liquidationERC20PoolHandler.drawDebt(54, 1078707919809097500728008, 0);
        _liquidationERC20PoolHandler.takeAuction(2, 11014481, 0, 0);
        _liquidationERC20PoolHandler.kickWithDeposit(6261145081390052923416, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);
        _liquidationERC20PoolHandler.repayDebt(2, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0);
        _liquidationERC20PoolHandler.repayDebt(19522111312004366551699434321235702562902449, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(2, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.kickAuction(1, 2109173590696846176713716365608775182694735853511202473079, 1, 0);
        _liquidationERC20PoolHandler.kickAuction(2, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_fenwick_prefixSumIndex_F4();
    }

    function test_regression_invariant_F4_4() external {
        _liquidationERC20PoolHandler.kickAuction(2, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        invariant_fenwick_prefixSumIndex_F4();
    }

    function test_regression_invariant_bucketlps_B2_B3() external {

        _liquidationERC20PoolHandler.takeAuction(267050932349, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 3887647445238399127687813856507958874, 0);
        _liquidationERC20PoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 103646259621272362812910538669334394369354710213939195837836110291707517186914, 22729901925249217583, 0);
        _liquidationERC20PoolHandler.takeAuction(100662313874952447676789537887446294, 36755077739534085766246321257993, 20000000001077187985112900413, 0);
        _liquidationERC20PoolHandler.settleAuction(999999999999999970610520171679024221920138860, 4339, 19021013243589608614756959415948670046791, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(7393406237507791712904627, 1097992169037390343, 30, 0);

        invariant_Buckets_B2_B3();
    }

    /* 
        Test was reverting when kicker is penalized when auction price > neutral price.
        Fixed by making changes in increaseInReserve calculation in case of kicker penalty in 'bucketTake' handler
    */
    function test_regression_evm_revert_1() external {
        _liquidationERC20PoolHandler.settleAuction(91509897037395202876797812344977844707030753189520454312427981040645023300162, 2439649222, 11529, 0);
        _liquidationERC20PoolHandler.bucketTake(6611, 46752666614331262781920, false, 2023645493297626462000000, 0);
    }

    // Test reverting with overflow error in dwatp calculation in _meaningfulDeposit in updateInterestState
    function test_regression_evm_revert_2() external {
        _liquidationERC20PoolHandler.drawDebt(13141077791835967310451371165744721774, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _liquidationERC20PoolHandler.kickAuction(3, 53758605435723729358784, 3, 0);
        _liquidationERC20PoolHandler.repayDebt(668608315443216098571064749198163965820, 18932325376258851353179065817321260901, 0);
        _liquidationERC20PoolHandler.pullCollateral(1660943750216, 7613674427701330576720241, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(1900819281467749758886813834006, 976636367449728350520609392573, 4111426995539375716119348324981, 0);
        _liquidationERC20PoolHandler.bucketTake(1125834907286324, 3, false, 1, 0);
        _liquidationERC20PoolHandler.repayDebt(275298270790660321974310940, 2799, 0);
        _liquidationERC20PoolHandler.pullCollateral(0, 9824, 0);
        _liquidationERC20PoolHandler.takeAuction(8838, 14328, 1104, 0);
        _liquidationERC20PoolHandler.pullCollateral(96246301775147975236686390, 1999999999999999999999999999999999999999999994, 0);
        _liquidationERC20PoolHandler.drawDebt(1799754463155649601, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.addCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.kickAuction(226, 13555, 999999999999999999929986989979848322131950166, 0);
        _liquidationERC20PoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 326707485783, 5838136568597409883953276821351359808349885898573251821, 0);
        _liquidationERC20PoolHandler.bucketTake(3690337820519065642096193886544, 3089359908022049919104337883638, false, 2000000000000000000000000000000000000000744145, 0);
        _liquidationERC20PoolHandler.withdrawBonds(117305399704678010034227969424174482909936628260540487, 3984313975337, 0);
        _liquidationERC20PoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 26153396219420651226355270050749728507266848485707520383, 0);
        _liquidationERC20PoolHandler.removeCollateral(1999999999999997567145382180442515092966583434, 2757, 245342563594047897888988147512, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(298628345, 6995466652341859760028193450571035, 212241589093381072912741572164, 1961348773154021480632696081492, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(302104028381701071862379310831040316417001692505762, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 60362684677889414469182462544723956045205775540295406540387737, 2, 0);
        _liquidationERC20PoolHandler.bucketTake(2, 75288272353, true, 1, 0);
        _liquidationERC20PoolHandler.addCollateral(5005, 147331, 401909674630078222417654, 0);
        _liquidationERC20PoolHandler.transferLps(1029198447942867385425606035931054127523339423727036067, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0, 0);
        _liquidationERC20PoolHandler.kickWithDeposit(293745346792645466008958291, 16403, 0);
        _liquidationERC20PoolHandler.withdrawBonds(2, 2, 0);
        _liquidationERC20PoolHandler.moveQuoteToken(32224, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 6849415706965240690489344969517578351041775953402620986, 2148695314889429664161453614417855608352221, 0);
        _liquidationERC20PoolHandler.takeAuction(94448273410401913677340426062, 725811011514389123331573619988789182755239580450547667740684, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
        _liquidationERC20PoolHandler.kickAuction(741587127707329942048624377800, 636948139808655918956339428997, 1638145676855893651071922500909, 0);
        _liquidationERC20PoolHandler.removeCollateral(1, 5658503566441554287849, 301974090866276112427896384335355, 0);
        
        /* Logs for t0Debt2ToCollateral, dwatp calculation in `drawDebt(AmountToBorrow: 0 ,collateralPledged: 1)`
            Time skipped after previous t0Debt2ToCollateral update = 2 hours
            colPreAction_                                          = 0
            colPostAction_                                         = 1
            debtPreAction_                                         = 855551635718176874927403250766
            debtPostAction_                                        = 855551635718176874927403250766
            debt2ColAccumPreAction                                 = 0
            debt2ColAccumPostAction                                = 731968601380048024642438738674823616825204760499344279586756
            t0Debt2ToCollateral Before _updateT0Debt2ToCollateral  = 2387420128063989411532277676228153
            t0Debt2ToCollateral After _updateT0Debt2ToCollateral   = 731968601380048024642438741062243744889194172031621955814909
            inflator_                                              = 1140475256675307106
            t0Debt2ToCollateral_                                   = 731968601380048024642438741062243744889194172031621955814909
            t0Debt_                                                = 1783948099616302823918411453377
        */
        _liquidationERC20PoolHandler.pledgeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639934, 1, 0);
    }

    /*
        F1 and F2 invariants were failing in `settleAuction` handler with difference between pool deposit and fenwick deposits of <1e17 but >1e16 for deposits of order 1e25
        Fixed by changing epsilon in F1, F2 from 1e16 to 1e17.
    */
    function test_regression_invariant_settle_F1_5() external {
        _liquidationERC20PoolHandler.settleAuction(0, 28071594006178250681754737955033434168, 2, 0);
        _liquidationERC20PoolHandler.bucketTake(1730972569841431578573774649270, 10903, false, 1175990817123654468079021581951, 0);
        _liquidationERC20PoolHandler.addQuoteToken(18695, 12463, 370340205846027014555877964321, 0);
        _liquidationERC20PoolHandler.takeAuction(631894654554387507015513816632, 16008, 1016878400672168648586524, 0);
        _liquidationERC20PoolHandler.settleAuction(0, 10186616154253336796368, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);

        /* Logs for settleAuction
            Pool deposit at 2572 after accrue interest                 -> 2032689444945695599645197
            local Fenwick deposit at 2572 after accrue interest        -> 2032689444928384299157690

            maxSettleable borrower debt                                -> 1004975124378109460799907

            Pool deposit at 2572 after settlePooldebt                  -> 1027714305720790052619170
            Required Pool deposit after subtracting maxSettleable      -> 1027714320567586138845290
            Precision error in unscaled remove                         -> 14846796086226120

            local Fenwick deposit at 2572 after settlePooldebt         -> 1027714320550274838357783
            Required local fenwick after subtracting maxSettleable     -> 1027714320550274838357783

            Final Difference between pool deposit and local fenwick    -> 14829484785738613
        */
        invariant_fenwick_depositAtIndex_F1();
        invariant_fenwick_depositsTillIndex_F2();
    }

    // Test failing due to exchange rate being calculated as 0
    function test_regression_evm_revert_200_depth_1() external {
        _liquidationERC20PoolHandler.repayDebt(115792089237316195423570985008687907853269984665640564039457584007913129639933, 32922171886372397025461758359678058354586052144795367851416216, 29149708811938844258185677588876);
        _liquidationERC20PoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 2, 1, 44112020970813247225385343986164375242000169293533273283527281409028027731783);
        _liquidationERC20PoolHandler.withdrawBonds(7926394667022825213918856805, 8353, 760724779507062772828300779648512696815905834011116868437034368211773017);
        _liquidationERC20PoolHandler.drawDebt(1650395907908375370646803, 1139089764268016448008730470211, 13082959110942300185021122222306626);
        _liquidationERC20PoolHandler.moveQuoteToken(93610, 142089797548946945081634619871556783127580529081355187339115302, 149, 13913579372905540408633068050774982611379962730, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _liquidationERC20PoolHandler.transferLps(6292165613120549248648866955393, 1060631736309413465, 3996, 5500900090246881585205428293671181, 91068871115322271162237280834);
        _liquidationERC20PoolHandler.kickWithDeposit(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3, 21453159328299531749810384996740705004989165577317322746872305568189);
        _liquidationERC20PoolHandler.drawDebt(10636347319675315313277232412888, 3051548607055529278657663362826, 5726786973904835518002557614676);
        _liquidationERC20PoolHandler.moveQuoteToken(1253192623581620772476304176589, 1004709840617137359, 1363507508709197960, 1733464339886107498992567200861, 7507);
        _liquidationERC20PoolHandler.withdrawBonds(1999999999999997715165989367948945659933163524, 1668463998534567849013477923041, 6990477785303516774672173634812);
        _liquidationERC20PoolHandler.repayDebt(370156721356394741, 172889287526810870997726036, 2919142786755286172671287957331);
        _liquidationERC20PoolHandler.addCollateral(291871857294519226882387742423649871023745205180404, 7032, 3, 3);
        _liquidationERC20PoolHandler.removeQuoteToken(19086136615689377380071157332, 1000016340952587544, 1269638071204883587, 1322590872902949122765936390014);
        _liquidationERC20PoolHandler.takeAuction(0, 105262958558340390379651824224551976850657241393189852, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1442109703618841621001866737093982407755182032393384);
        _liquidationERC20PoolHandler.pullCollateral(60686734430098688980363534701, 6645, 244505533695904154540052960522);
        _liquidationERC20PoolHandler.takeAuction(4885706793554589184578584463228746134028180231574229781748506559634, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 17050067398218, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _liquidationERC20PoolHandler.withdrawBonds(144829687990416439852964636231, 1205912031800815111535, 0);
        _liquidationERC20PoolHandler.removeQuoteToken(6642410103013296011493426900343, 2492426819368674523, 3266897935879438277566082088672, 9726148562415536773559536515825);
        _liquidationERC20PoolHandler.removeCollateral(1963099933, 11654617284621063852973339264120, 3625603614157547310899003896756902, 1121433320471955127);
        _liquidationERC20PoolHandler.removeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639934, 504174, 0, 2);
        _liquidationERC20PoolHandler.settleAuction(998590020496406658903618279132591123787, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _liquidationERC20PoolHandler.moveQuoteToken(2, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 7284471812509773537205732476838343788700345614979848008809137811380867, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        /**
            bucket.collateral 7032
            bucket.lps 490878978529.677715644529836886
            bucketDeposit 0
            bucketPrice 2711.489231884282943350
            in quoteTokensToLP rate is calculated as 0
         */
        _liquidationERC20PoolHandler.removeQuoteToken(6639226178282709423409930834969, 2197, 7172732911536352257734091713604, 1332571387535482575409273685828232);

        invariant_total_interest_earned_I2();
    }

}