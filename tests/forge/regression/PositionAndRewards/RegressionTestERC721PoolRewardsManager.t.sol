// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import { ERC721PoolRewardsInvariants } from "../../invariants/PositionsAndRewards/ERC721PoolRewardsInvariants.t.sol";

contract RegressionTestERC721PoolRewardsManager is ERC721PoolRewardsInvariants {

    function setUp() public override { 
        super.setUp();
    }

    // issue in invariants totalling amount of rewards that caller of claimRewards was receiving.
    // fix: claimrewards and update rewards now go to caller of claimRewards
    function test_regression_failure_rewards_exceeded_claim() external {
        _erc721poolrewardsHandler.settleAuction(17873, 2208, 326, 1944);
        _erc721poolrewardsHandler.stake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 53134310333307170138, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 2340533661754158540520179666008670241532871916995373825004189326661505987844);
        _erc721poolrewardsHandler.pledgeCollateral(8132, 11716, 1057);
        _erc721poolrewardsHandler.kickReserveAuction(2985325127, 23214);
        _erc721poolrewardsHandler.removeCollateral(3461, 514, 17285, 838);
        _erc721poolrewardsHandler.kickAuction(18170, 652, 11342, 1168);
        _erc721poolrewardsHandler.pullCollateral(20130, 1209987167530552461153974115173428229758989546163, 150941);
        _erc721poolrewardsHandler.moveLiquidity(63198806135952229891699111929727509482991997027848329114178785250303971081388, 77371051183995213971267347974759461809434770063921461351617080426027329266071, 4805, 2289);
        _erc721poolrewardsHandler.moveLiquidity(63198806135952229891699111929727509482991997027848329114178785250303971081388, 77371051183995213971267347974759461809434770063921461351617080426027329266071, 4805, 2289);
        _erc721poolrewardsHandler.moveQuoteToken(276169773153138481519606288636310061814657663456104947149, 1, 0, 108537837119796081908394324659000725292282331478997011952318493996290, 155532253556112179854090944828383440910501711771906801208685755840667262568);
        _erc721poolrewardsHandler.mergeCollateral(173, 22406963037383631220938302497939718111833223267188040374368716127276);
        _erc721poolrewardsHandler.burn(1328065707762407283002828802143541176473931677425004844, 1, 1, 37613208758526068006052551033711685);
        _erc721poolrewardsHandler.takeAuction(0, 9352381759360299323960711216326149317387010227218710, 2546377053981808421495007542941590246694727231217, 3663797758192519198918);
        _erc721poolrewardsHandler.takeAuction(148878580729371224992950595085688885987, 52018, 3863548495672151022795311051855, 1224829895266858456828928840866630331525272263026827096173292323394330361);
        _erc721poolrewardsHandler.claimRewards(339802229099465406190265268924204103831957337149846935, 1, 2641, 1084164255431, 3);
    }

    // issue in _preDrawDebt when borrower is in auction and tried to repayDebt and pull collateral, and check all debt is repaid.
    // fix: return _preDrawDebt when borrower is in auction.
    function test_regression_RW1_RW2() external {
        _erc721poolrewardsHandler.stampLoan(3097, 99133);
        _erc721poolrewardsHandler.kickAuction(31354931781638678607228669297131712859126084785867252355217498662940140921971, 1058, 11754, 12849);
        _erc721poolrewardsHandler.takeReserves(115792089237316195423570985008687907853269984665640564039457584007913129639934, 33731052920955697617409005891040394080922214120333458396693390120882665651,1720188968454217720935353179268130063921306460048647700482);
        _erc721poolrewardsHandler.pledgeCollateral(1757924641683012822782278927906643733124399771812893540782608051864, 146672722799504441441256193696, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _erc721poolrewardsHandler.mint(12138, 7557);
        _erc721poolrewardsHandler.addQuoteToken(13384168457563664686794224199997478429074004894884217417626102307452469562, 399627080535825658763553985697630307858997509589356607284924675010621,15021260382761, 2149748001246586660242584607929003545953);
        _erc721poolrewardsHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _erc721poolrewardsHandler.settleAuction(1735287903719074628042764789671363295, 3, 23993967057076184216275526949268, 4106476);
        _erc721poolrewardsHandler.drawDebt(77622297016072599381603815616169164633892036937355547901, 10261965, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _erc721poolrewardsHandler.stampLoan(115792089237316195423570985008687907853269984665640564039457584007913129639934, 15628038388);
        _erc721poolrewardsHandler.redeemPositions(22801150734449629332972378409816953484259939113298558, 563212509531357473751756674, 236487328781308137707, 114005983);
        _erc721poolrewardsHandler.unstake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 209638772009545859528, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1852809668170365878555741120106, 8537278537524035545583862060040379261058217549);
        _erc721poolrewardsHandler.emergencyUnstake(5762, 4833, 23085, 23329, 10160);
        _erc721poolrewardsHandler.lenderKickAuction(38567162678744729883825485304193880641, 1436018647533119237198979383384378157898748977466826312550, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _erc721poolrewardsHandler.mergeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639935, 40700253390048296022217103829550);
        _erc721poolrewardsHandler.stake(115792089237316195423570985008687907853269984665640564039457584007913129639935, 13666289603396405051, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 105);
        _erc721poolrewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 1, 28190);
        _erc721poolrewardsHandler.kickReserveAuction(1886, 65412);
        _erc721poolrewardsHandler.takeReserves(7740, 4448, 3713);
        _erc721poolrewardsHandler.pullCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1);
        _erc721poolrewardsHandler.repayDebt(110349606679412691172957834289542550319383271247755660854362242977991410020198, 6715, 4023);
        _erc721poolrewardsHandler.mergeCollateral(0, 59747238056737534481206780725787707244999);
        _erc721poolrewardsHandler.emergencyUnstake(0, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 51729897709415, 23006395802429129288475054106, 1);
        _erc721poolrewardsHandler.removeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639934, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _erc721poolrewardsHandler.bucketTake(17736, 12855, false, 3289, 1123);
        _erc721poolrewardsHandler.pledgeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1);
        _erc721poolrewardsHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1347071909069112433439054986249189622, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _erc721poolrewardsHandler.lenderKickAuction(3, 1, 37246476355849);
        _erc721poolrewardsHandler.failed();
        _erc721poolrewardsHandler.burn(143, 1108823922,48884, 5811);
        _erc721poolrewardsHandler.memorializePositions(7222, 6164, 14919869490272923636577259832825010352693700464430964509126832818182799243080, 26284);
        _erc721poolrewardsHandler.takeAuction(1110452889, 6058, 3016184996, 12922961544511690602711642372921216522520321844072048399134131509470247863750);
        _erc721poolrewardsHandler.mergeCollateral(5967, 3326);
        _erc721poolrewardsHandler.bucketTake(1, 1714375381109265815411514882158434660321706149315054174553444757, true, 2, 2);
        _erc721poolrewardsHandler.unstake(3, 28372160064709526166669973508287087795611038423150717571367, 54636530394327258458081903942670329383, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _erc721poolrewardsHandler.updateExchangeRate(36456, 17137, 1560275421, 17005);
        _erc721poolrewardsHandler.stampLoan(3352512690189013572483301109122336596527121909930416357921778362671464454374, 5992531996617362563537972);
        _erc721poolrewardsHandler.pledgeCollateral(174922928606654802364580162287611825, 4, 56551201532130900086);
        _erc721poolrewardsHandler.emergencyUnstake(2247288760962719055600016280767970105290, 0, 2, 11596164422216101546875614140375574915418729056483, 61337865928763100451538345828);
        _erc721poolrewardsHandler.emergencyUnstake(1023240505530161435702165, 18496758270674070880, 45978599603359075781444831263900707496437331655382222738127705004512629605795, 110349606679412691172957834289542550319383271247755660854362242977991410020756, 4078);
    }
    
    /**
        Test was failing due to rounding error converting LP to quote token.
        Fixed by updating UnboundedLiquidationPoolHandler._bucketTake to handle such error.
     */
    function test_regression_failure_rewards_overflow() external {
        _erc721poolrewardsHandler.takeAuction(8916353616233254, 57649844002245701248730112897897147833956884330328914675231893131196499, 2, 1018952559902734233814512249);
        _erc721poolrewardsHandler.kickAuction(112736415470012592, 3, 19278963085894, 9237232408666728270833285496218833069432038626883825559658640793085);
        _erc721poolrewardsHandler.bucketTake(28824487368408363332698335936007285757564893920182, 115792089237316195423570985008687907853269984665640564039457584007913129639934, false, 1040619669142172520180282659955444878977545389729, 2);
        _erc721poolrewardsHandler.takeReserves(1, 1690356436532074570533930338584095153497166666596823569518358218435994901, 4739783432096360237158878972162547413944);
        _erc721poolrewardsHandler.lenderKickAuction(2, 149988654945892111475580398315373862917318723676137274344441, 37649956223046754466133865019811756431246961730193050216);
        _erc721poolrewardsHandler.settleAuction(45810009176994727315788613568638152379627551265312380747603346250712722782924, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 2);
        _erc721poolrewardsHandler.addCollateral(19483612075505036007841503054, 1677153748, 1000070628921045446, 1148172);
        _erc721poolrewardsHandler.transferLps(115792089237316195423570985008687907853269984665640564039457584007913129639935, 291639400231321636162168623657270265913850045, 215754681139626220523368, 5226127817218383855927301746913296170330111547385428, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _erc721poolrewardsHandler.addQuoteToken(323374494529054033243819637344556640065034763, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 1259731035345409005904471362717674, 99941238583556635863367813776996390291236249258162197109890524114914358742);
        _erc721poolrewardsHandler.lenderKickAuction(16784630371, 22375981509714230512428795288763677975132136672347920486970961655311934, 3);
        _erc721poolrewardsHandler.memorializePositions(468093663764110, 4656939962607829550111302107525637718412222259617754699, 7287334179041, 0);
        _erc721poolrewardsHandler.withdrawBonds(9367606986747103919885048459, 689920112970643606556493182059452121941051682581550050310301299581924353, 37821799888461958928546256012744431300593518619764500683804065846096008348141);
        _erc721poolrewardsHandler.updateExchangeRate(1689180492, 3715933165206242091035217822, 1016916006775448157, 1001489633337895443364172082379);
        _erc721poolrewardsHandler.pledgeCollateral(5698428495804149158171591586673967207792973, 8090859, 1);
        _erc721poolrewardsHandler.bucketTake(3121885286313153131128327608, 697281633448180542496880052709708157452138653993092814064064701187489793, false, 3694932, 4372051719140541081430084487);
        invariant_rewards_RW1_RW2();
    }
}
