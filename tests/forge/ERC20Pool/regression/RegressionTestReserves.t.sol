// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import { ReserveInvariants } from "../invariants/ReserveInvariants.t.sol";

contract RegressionTestReserve is ReserveInvariants { 

    function setUp() public override { 
        super.setUp();
    }   

    function test_regression_reserve_1() external {
        _reservePoolHandler.kickAuction(3833, 15167, 15812);
        _reservePoolHandler.removeQuoteToken(3841, 5339, 3672);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    // test was failing due to error in local fenwickAccureInterest method
    function test_regression_reserve_2() external {
        _reservePoolHandler.bucketTake(19730, 10740, false, 15745);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
        _reservePoolHandler.addCollateral(14982, 18415, 2079);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_3() external {
        _reservePoolHandler.repayDebt(404759030515771436961484, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
        _reservePoolHandler.removeQuoteToken(1, 48462143332689486187207611220503504, 3016379223696706064676286307759709760607418884028758142005949880337746);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_4() external {
        _reservePoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1);  

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_5() external {
        _reservePoolHandler.addQuoteToken(16175599156223678030374425049208907710, 7790130564765920091364739351727, 3);
        _reservePoolHandler.takeReserves(5189, 15843);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, false, 32141946615464);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_6() external {
        _reservePoolHandler.addQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.removeQuoteToken(3, 76598848420614737624527356706527, 0);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_7() external {
        _reservePoolHandler.addQuoteToken(3457, 669447918254181815570046125126321316, 999999999837564549363536522206516458546098684);
        _reservePoolHandler.takeReserves(0, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.takeAuction(1340780, 50855928079819281347583122859151761721081932621621575848930363902528865907253, 1955849966715168052511460257792969975295827229642304100359774335664);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_8() external {
        _reservePoolHandler.addQuoteToken(0, 16517235514828622102184417372650002297563613398679232953, 3);
        _reservePoolHandler.takeReserves(1, 824651);
        _reservePoolHandler.kickAuction(353274873012743605831170677893, 0, 297442424590491337560428021161844134441441035247561757);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_9() external {
        _reservePoolHandler.addQuoteToken(8167, 13910, 6572);
        _reservePoolHandler.removeQuoteToken(450224344766393467188006446127940623592343232978, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 3);
        _reservePoolHandler.addQuoteToken(1338758958425242459263005073411197235389119160018038412507867175716953081924, 0, 3);
        _reservePoolHandler.removeQuoteToken(13684, 7152374202712184607581797, 37874588407625287908455929174);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_10() external {
        _reservePoolHandler.drawDebt(3, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.takeAuction(57952503477150200455919212210202824, 59396836510148646246120666527, 253313800651499290076173012431766464943796699909751081638812681630219);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_11() external {
        _reservePoolHandler.drawDebt(121976811044722028186086534321386307, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _reservePoolHandler.removeQuoteToken(22099, 75368688232971077945057, 1089607217901154741924938851595);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_12() external {
        _reservePoolHandler.drawDebt(7201, 13634);
        _reservePoolHandler.startClaimableReserveAuction(4584);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_13() external {
        _reservePoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 540213858694280098848655811354140073005);
        _reservePoolHandler.takeAuction(0, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 16744276840254269931315148200783781329474);
        _reservePoolHandler.settleAuction(1052055081946638635908683442568, 2, 3);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_14() external {
        _reservePoolHandler.settleAuction(437841947740231831335707997666789355668988087441752683415964733126988332082, 147808166723925302409649247274, 115792089237316195423570985008687907853269984665640564039457584007913129639934);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_reserve_16() external {
        _reservePoolHandler.kickWithDeposit(24364934041550678417946191455, 52607039466540426076659653665991);
        _reservePoolHandler.moveQuoteToken(12701858085177571414571267592, 42692775850651681314985098497603, 999999999999999997089137720115121650200233243, 110756792431977317946585133);
        _reservePoolHandler.takeReserves(1000000005297961791, 4169814726576748738687746199368099036929520400874217254297794929654231);
        _reservePoolHandler.takeReserves(3052809529665022333893308239466671666604242469878272137069, 2);
        _reservePoolHandler.settleAuction(56829802927206056542134152487104, 1, 16551256);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 4559892907266199616760, true, 92132592320410512639572628067656882480659844625060229234412683145);
        _reservePoolHandler.addQuoteToken(26659, 27252796304289191617124780530313880584663397025838797405583704016009646047240, 8174069071114126926049883726727);
        _reservePoolHandler.settleAuction(7416752279321695807446009676282848840713503167567654621163487831711306738, 42429259698839522507819580090756, 4353185348715295869540288672);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 1, true, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.takeReserves(7414584624540108578389380660398591567646816233407392320795021351932076518, 119186585263660671065239170291646549528129172578);
        _reservePoolHandler.takeReserves(14604452466686952199052773378, 15308);
        _reservePoolHandler.moveQuoteToken(2, 7113439765, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 101839127799233627783);
        _reservePoolHandler.drawDebt(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3);
        _reservePoolHandler.removeQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639935, 175006273713916823228319530732179, 3);
        _reservePoolHandler.kickAuction(999999999999999989948035804259829580593704779, 2999999999999999995605838724439103323477035837, 567178035339127142779327214);
        _reservePoolHandler.kickWithDeposit(17028734043909648834002499445, 9578925065330517200577552073309);
        _reservePoolHandler.addQuoteToken(6672165, 3776221923932077947607417775990788567, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_fenwick_deposits_1() external {
        _reservePoolHandler.pledgeCollateral(2, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.takeAuction(2, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 22181751645253101881254616597347234807617);

        invariant_fenwick_depositAtIndex_F1();
        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_regression_incorrect_zero_deposit_buckets_1() external {
        _reservePoolHandler.addQuoteToken(26716, 792071517553389595371632366275, 1999999999999999449873579333598595527312558403);

        invariant_fenwick_prefixSumIndex_F4();
        _reservePoolHandler.takeAuction(3383098792294835418337099631478603398072656037191240558595006969488860, 23280466048203500609787983860018797249195596837096487660362732305, 999999999999999999999999012359);

        invariant_fenwick_prefixSumIndex_F4();
    }

    function test_regression_incorrect_zero_deposit_buckets_2() external {
        _reservePoolHandler.addCollateral(9093188371345232280759885514931620, 736370925, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.removeQuoteToken(2, 743823342719479363729966668312423206558602, 6003791801508574660825548152233943700089469549364090309);
        _reservePoolHandler.removeQuoteToken(261467129238591107899210386032213509797152237956889, 1034, 48028560549472995);
        _reservePoolHandler.addQuoteToken(261467129238591107899210386032213509797152237956889, 1034, 48028560549472995);
        _reservePoolHandler.drawDebt(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.addQuoteToken(22558, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 26798251134);
        _reservePoolHandler.moveQuoteToken(699684583201376669946795465695023954383, 871337618071093223322748209250657757655686665685488924893819949988, 6856667370119202181100844692321254723509125063768335, 2);
        
        invariant_fenwick_prefixSumIndex_F4();

    }

    function test_regression_incorrect_bond() external {
        _reservePoolHandler.settleAuction(18129, 6125, 756);

        invariant_bond_A2();
        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_reserves_fenwick_depositAtIndex_F1() external {
        _reservePoolHandler.kickAuction(14062, 13380, 20332);
        _reservePoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 250713412144308447525906089113510093407014793436690623);
        _reservePoolHandler.bucketTake(2, 115792089237316195423570985008687907853269984665640564039457584007913129639933, true, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_fenwick_depositAtIndex_F1();
    }

    function test_regression_invariant_reserves_settle_1() external {
        _reservePoolHandler.settleAuction(2999999999999999543503680529282898884169444286, 999999999999999999999999, 6952);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 0, false, 228076556654255348886);
        _reservePoolHandler.startClaimableReserveAuction(18407833277983020451007887294192863287187933);
        _reservePoolHandler.settleAuction(2720, 3319, 516);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_reserves_settle_2() external {
        _reservePoolHandler.takeAuction(3, 214198155653990209702223102757081411626927025, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.repayDebt(36, 19087);
        _reservePoolHandler.drawDebt(2550145944163683156825587547113715005197220288637184, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_reserves_invariant_quoteTokenBalance_QT1_1() external {
        _reservePoolHandler.kickAuction(22771, 1111716442170237736883602263032, 7068);
        _reservePoolHandler.addCollateral(450013003559446434159001584489461823249847174057443177111241841181931, 312804075096415570730723645176181753809227168111076176815108, 0);
        _reservePoolHandler.pledgeCollateral(1985831902099838153679635097394320832859625435, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.transferLps(1, 11785568695658463091194696857966812287312218400594, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 0);
        _reservePoolHandler.takeAuction(159178586166894, 2, 2);
        _reservePoolHandler.kickAuction(2, 2375789919282905103386504516485994899, 1289653);
        _reservePoolHandler.startClaimableReserveAuction(2162);
        _reservePoolHandler.settleAuction(4612, 40708630701038224142448353799854069842509049093396550723073072047814079, 39027373949250548040512012762457247677933424051240699689883568078322057459524);
        _reservePoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 1);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_invariant_reserves_invariant_quoteTokenBalance_QT1_2() external {
        _reservePoolHandler.drawDebt(1, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _reservePoolHandler.pullCollateral(8213783947977569843117913236674123519747026, 26007879196259510050186964175498569516185804333067186877);
        _reservePoolHandler.drawDebt(2301679051848045604, 2599238865);
        _reservePoolHandler.addCollateral(4242066606167690018840733069974159, 2308657525655903223461843364795, 65478701235782653506998474972558);
        _reservePoolHandler.kickAuction(69087967303211947138147234149237227681311399268590256122007, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 61509477439);
        _reservePoolHandler.bucketTake(72107205250762587233492136850, 1244277915808615586782916545843, false, 39013151190969055659579687996);
        _reservePoolHandler.transferLps(235427298074932216827475360756961, 2730975142229662626738653393718571, 1801094436838792863068211758488417, 879376648610435813515943108046);
        _reservePoolHandler.bucketTake(740590071845914415309602438961, 903524249678397461462482055179, false, 999387178588229710810342952208);
        _reservePoolHandler.settleAuction(1996, 648686406391068869253434465091, 1012371126513011680823527365765);
        _reservePoolHandler.kickAuction(2758621226294910077454620848, 1587186203667651966808515455274, 999999999999999766114657929326397241693634383);
        _reservePoolHandler.startClaimableReserveAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.addCollateral(860262795452324500467615408841617417042130132486395050948571309437624254, 88294053979131610681224002926017918012056109605052596771915843, 2509079085932223405093441153560904865353589);
        _reservePoolHandler.drawDebt(3, 2);
        _reservePoolHandler.bucketTake(1112272948946288199596319174059, 651469309530642638235774421, false, 2631651594321033821284801688396855);
        _reservePoolHandler.pullCollateral(1, 104099149887771887762252474591136544290691758);
        _reservePoolHandler.addQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3893316282729587584044696989905829964749218951828499823513945610388772348, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.addCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639933, 1079490131956486279124163833769398638737841713956621, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _reservePoolHandler.startClaimableReserveAuction(0);
        _reservePoolHandler.settleAuction(1685708597792729438175883702650, 2952680495818774014078, 5097264761526793300787284458);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_invariant_reserves_invariant_quoteTokenBalance_QT1_3() external {
        _reservePoolHandler.addQuoteToken(2, 2, 306147942052277777154794038508061442);
        _reservePoolHandler.takeReserves(999999997592778230040335721194842507878613188, 617767166532412476599141189);
        _reservePoolHandler.startClaimableReserveAuction(103210968180742388081044815736108888392928341723424194324988612249639);
        _reservePoolHandler.kickWithDeposit(571331675273077569870268525690, 3000000000000000153070529032047742375224439804);
        _reservePoolHandler.transferLps(115792089237316195423570985008687907853269984665640564039457584007913129639935, 1, 2345974107770202992, 596944268880651135381308885897365469741047535828013376978854456255492067);
        _reservePoolHandler.kickAuction(249542131817080594576330466916380605939068941221926774088755, 1792443579171442237436215, 2);
        _reservePoolHandler.settleAuction(2475430586786710276861336070835, 2600907908657087816392951766665339, 618867463233346276220185869);
        _reservePoolHandler.bucketTake(288221154502730111886403777699180, 4013402100758707152779826705918182, false, 3000000000000000997154081605746206372402043417);
        _reservePoolHandler.addQuoteToken(9798212016992127202141315997364967680599055895, 3, 1072606682991056733959287049686598376179068454808322552897362615);
        _reservePoolHandler.pledgeCollateral(153445992298474361671974195535972272220394541157224893523804178985601, 53709221935782524388066885085801417);
        _reservePoolHandler.startClaimableReserveAuction(1);
        _reservePoolHandler.bucketTake(3, 1, true, 2);
        _reservePoolHandler.settleAuction(2518428390102925899809538437634001, 351638851502181329392182678513150532940060325784767627878107695205, 3071611172974674710789364893);
        _reservePoolHandler.transferLps(28822226972612722036870301886639533933908463827921999334463168, 1, 314514798153750347019311, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _reservePoolHandler.pullCollateral(2, 2);
        _reservePoolHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 60110048782249025340, 115792089237316195423570985008687907853269984665640564039457584007913129639932);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_invariant_reserves_invariant_quoteTokenBalance_QT1_4() external {
        _reservePoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.repayDebt(123785744463475277851, 431477);
        _reservePoolHandler.transferLps(8349868629210939854344368826901611192, 2050523511941068426657597285533, 482178822629563486190079445656644, 113294184847064316812952522804);
        _reservePoolHandler.kickWithDeposit(115792089237316195423570985008687907853269984665640564039457584007913129639934, 1);
        _reservePoolHandler.settleAuction(2, 60232917818899277216367937385395389606, 109871490879953029603376159938904259489696033217506136);
        _reservePoolHandler.repayDebt(11000946587948121111587595267746251370302202324589596297423219199459160, 1640564753028103680512592653747);
        _reservePoolHandler.kickAuction(3981871706795545560915874060150150667177950440617972926122855684987, 198277768150818655020367, 2892877132676919180494078569276042);
        _reservePoolHandler.addCollateral(1263277608, 63278488014355910828533249093658068159654702008400, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.pullCollateral(2673207612857671157084473752324442, 2000121050152966887141053752381);
        _reservePoolHandler.removeCollateral(17512256671104333742254942029, 940622488995047370832475, 17490);
        _reservePoolHandler.takeReserves(4664936529054748613171449032640911546982046023628226142220220474, 12228144613454452340256380805978754348438442703119);

        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_invariant_reserves_invariant_quoteTokenBalance_QT1_5() external {
        _reservePoolHandler.settleAuction(841361270493647884419014561906636, 98291268956781519518581599501066994252857442823583923678216713962377882453983, 1406581758883);
        _reservePoolHandler.takeAuction(1383411077269858329680139336144799098803584219410295488, 3, 0);
        _reservePoolHandler.repayDebt(46968019084877, 3);
        _reservePoolHandler.settleAuction(40124885934647691486197516987534429290957609634434455185985854549948025389553, 7413335529509918122196253760378, 3);
        // _reservePoolHandler.bucketTake(17377, 2748873005452892812548622619587, false, 999999999999999989712357375741033502535274466);
        skip(2 hours);
        _pool.updateInterest();
        /*
         TODO: Check why deposit change is more than debt change in accrue interest in "updateInterest"
         debt change          --> 236352821760996207141053
         deposit change       --> 236352821761181451576056
        */
        currentTimestamp = block.timestamp;
        invariant_quoteTokenBalance_QT1();
    }

    function test_regression_invariant_reserves_settle_3() external {
        _reservePoolHandler.bucketTake(38522325070060518315904717784000000000, 74804166371079302281493396778, false, 243284095655821418741726406906);
        _reservePoolHandler.removeQuoteToken(63300517263709739718213296806, 544282601310994378458621785271097, 93004761485750531023207874);
        _reservePoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 10850580031398165201080403693039642, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _reservePoolHandler.takeAuction(1006654503300439100037731502194, 999999999999999820916638470184939411687495097, 2999999999999999849116243910762621146260836956);
        _reservePoolHandler.settleAuction(513358560825207984200760701, 527826952804937875408570995575150, 3075);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_reserves_settle_4() external {
        _reservePoolHandler.kickAuction(999999999999999886611844846637902655009191722, 809319421722186623206028334686443, 33424777291596678039713);
        _reservePoolHandler.addQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3, 2503088493515274266);
        _reservePoolHandler.drawDebt(115792089237316195423570985008687907853269984665640564039457584007913129639934, 16755);
        _reservePoolHandler.removeQuoteToken(115792089237316195423570985008687907853269984665640564039457584007913129639932, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.settleAuction(3, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 2);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_take_reserves_1() external {
        _reservePoolHandler.drawDebt(3, 2472487412192096145519673462983934503);
        _reservePoolHandler.takeReserves(115792089237316195423570985008687907853269984665640564039457584007913129639933, 50482403089838632034016548451617756782);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_take_reserves_2() external {
        _reservePoolHandler.kickAuction(2, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.takeReserves(9990, 2);
        _reservePoolHandler.takeAuction(2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 32167191465467724730024789812);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_take_reserves_3() external {
        _reservePoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 7863893832813740178393566165935290555711);
        _reservePoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 672940003103495713632014456312899612181893075117989217767500902);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }

    function test_regression_invariant_take_reserves_4() external {
        _reservePoolHandler.bucketTake(0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, true, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.takeReserves(2000008144440715646777241504589, 695559613732339828463793224249);
        _reservePoolHandler.takeAuction(5260, 3000000000000000000000010654836333921317470662, 6571232818648673809695471386);

        invariant_reserves_RE1_RE2_RE3_RE4_RE5_RE6_RE7_RE8_RE9_RE10_RE11_RE12();
    }
    
    function test_regression_invariant_repayDebt_F2_1() external {
        _reservePoolHandler.takeAuction(1, 955139331336232548042968484715961932654029262247576677099836, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.addQuoteToken(19874832899, 2, 19674101910639560463031669634628955697045);
        _reservePoolHandler.kickAuction(1000000000372489032271805343253, 33527, 2999999999999998999627510967728193679786334003);
        _reservePoolHandler.takeAuction(30442763437987671335943625876181535412080651070033770037765737902267600059, 0, 62793434148368637031717982910725);
        _reservePoolHandler.drawDebt(1, 2);
        _reservePoolHandler.takeAuction(28478785935025462058931686388528614452411453327852591879599088, 1426479312070353, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.drawDebt(10933, 2937);
        _reservePoolHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 2, 6122968755523040);
        _reservePoolHandler.repayDebt(10917282482493108186780095138347753666882231491750232316870663654516774564, 115792089237316195423570985008687907853269984665640564039457584007913129639933);

        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_regression_invariant_takeAuction_F3() external {
        _reservePoolHandler.drawDebt(66012189296213, 3501011380219996136241089195497);
        _reservePoolHandler.kickAuction(5022297903775350684886398975, 20526, 2902853749630275072725962069);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 1, true, 4391496802861267555764811220);
        _reservePoolHandler.moveQuoteToken(26018560, 3192, 25995484456155391449642016017, 22537);
        _reservePoolHandler.transferLps(10763986310328530217005920827655704540417291683469924162879658, 4634, 8842, 3);
        _reservePoolHandler.settleAuction(2913861884801667469428509650, 17685440748964982730500143988068465999241920952718023027278539889735696458314, 744860398079104642573120377479575543713282684535849403581932752660396046);
        _reservePoolHandler.takeReserves(9546428924610247071820016, 1);
        _reservePoolHandler.kickAuction(1021712469506287128291988, 470273052888220, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _reservePoolHandler.kickWithDeposit(21372131561480654576901520848, 583255095299263976575486908);
        _reservePoolHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 219682941, 6398456408984021365251851328837461998816613070677747503909692892499751257833);
        _reservePoolHandler.moveQuoteToken(8413969458442105899430554342773, 42973831423907508485458560352, 14483994975746621772566970294, 27693669185946254354714892761);
        _reservePoolHandler.bucketTake(0, 1, false, 1);
        _reservePoolHandler.takeAuction(2760306433008897416497, 35178760526536102733112750779, 307455027758822287663945712);

        invariant_fenwick_bucket_index_F3();
        invariant_fenwick_prefixSumIndex_F4();
    }

    // FIXME: Seems to be an issue with Deposits.mult() in accrue interest or some issue with timestamp in invariant setup
    function _test_regression_kick_F1_F2() external {
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 1513638311409397559820116, false, 1107177539379);
        _reservePoolHandler.removeQuoteToken(11979868839631132246101, 1137392, 2);
        _reservePoolHandler.takeReserves(3, 398628895133942030524702233785087782308780160336206641843430908);
        _reservePoolHandler.takeAuction(296258719633565160185329, 490859840095298219320862, 16604700944401714968833692676);
        _reservePoolHandler.kickAuction(1007024558278734662013991074770, 12316238, 8522190612260582802728723964891359810344750053801981528212387048);
        _reservePoolHandler.takeAuction(999999999999999990212662818220103017885508577, 13644265990130681739980240101, 365402912996683431395427167362586262781607554542513822722975820380813222232);
        _reservePoolHandler.takeAuction(999999999999999990000000000000000000000993018, 31506548945590221240114018464, 1016963456957222995035464545);
        _reservePoolHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3, false, 30294494991681513847857232418933803770638682537);
        _reservePoolHandler.kickAuction(2324631542950979206383056100280239271207523734887421, 1, 23494016960770235530146856844201861803189848725938507629);

        invariant_fenwick_depositAtIndex_F1();
        invariant_fenwick_depositsTillIndex_F2();
    }

    function test_remove_regression_R1() external {
        _reservePoolHandler.takeAuction(1000000000147122258, 3919731510820678131056801, 158441107709132461742605107);
        _reservePoolHandler.repayDebt(15097247704276523502490912, 5821681489746654725611665637);
        _reservePoolHandler.addQuoteToken(409278183265946161107935122, 13459778251101474251175765782, 17131651646875762675637482511491680925564181440856864512);
        _reservePoolHandler.kickWithDeposit(3000000000000000000003060052276861736589117902, 10971651541557993591476169);
        _reservePoolHandler.drawDebt(99176811231448450752542388131222351, 4756085816094695387473840);
        _reservePoolHandler.transferLps(345464481275697722, 1, 1571, 636770839146216364947817981246144824780203402016795537219680499840300283500);
        _reservePoolHandler.takeReserves(1, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _reservePoolHandler.removeQuoteToken(2921676640197348125883567882, 110429299813004951706741973, 5838113258459267571531065497);

        invariant_exchangeRate_R1_R2_R3_R4_R5_R6_R7_R8();
    }


    function test_regression_reserve_exchange_rate_1() external {
        _reservePoolHandler.transferLps(841, 1020772463698588586, 14911, 4258);
        _reservePoolHandler.takeReserves(441, 1325437902620895068387062507934542597813850920030);
        _reservePoolHandler.takeReserves(147674730245938517022, 24252914314211360238410823746552653247);
        _reservePoolHandler.transferLps(6103, 18558, 526, 10043);
        _reservePoolHandler.repayDebt(14963, 47859675014730480218326115868817948026943509666409105929535555907127183589833);
        _reservePoolHandler.settleAuction(3, 17995718612397600820719751786479810453230621149400770516709318, 3744301747155532523890702823128853);
        _reservePoolHandler.removeCollateral(5718644755323, 208920569046185786607497873452448591730892, 115792089237316195423570985008687907853269984665640564039457584007913129639934);

        invariant_exchangeRate_R1_R2_R3_R4_R5_R6_R7_R8();
    }
}
