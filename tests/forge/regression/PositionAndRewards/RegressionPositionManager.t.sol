// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import { PositionsInvariants } from "../../invariants/PositionsAndRewards/PositionsInvariants.t.sol";

contract RegressionPositionManager is PositionsInvariants { 

    function setUp() public override { 
        super.setUp();
    }

    // Test was failing because handler was using unbounded bucketIndex
    // Fixed by bounding bucketIndex
    function test_regression_position_evm_revert_1() external {
        _positionHandler.memorializePositions(265065747026302585864021010218, 462486804883131506688620136159543, 43470270713791727776, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
    }
    
    // Test was failing because handler was using unbounded bucketIndex
    // Fixed by bounding bucketIndex
    function test_regression_position_evm_revert_2() external {
        _positionHandler.burn(3492, 4670, 248, 9615);
    }

    // Test was failing due to incorrect check in moveLiquidity handler
    // Fixed by updating Lps and depositTime checks in moveLiquidity
    function test_regression_position_moveLiquidity_assertions() external {
        _positionHandler.redeemPositions(3, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 383, 55401367687647196204681805934009816110);
        _positionHandler.memorializePositions(63114273171442586497890388, 154152435409657628166549200091090874517100159073873, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _positionHandler.memorializePositions(5108, 999999999999999999, 18382, 12291);
        _positionHandler.burn(138176025109205882910260935173830393, 486526542428702931007164500131103382164, 909564196488498523878255414236, 25516699);
        _positionHandler.moveLiquidity(0, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0, 3, 2);
    }

    // example has a divergence of the positionManager's depositTime from the actor tokenId's depositTime stored in positionManager
    function test_regression_position_deposittime_assertions() external {
        _positionHandler.burn(2361, 11336, 3859341707, 3646975496);
        _positionHandler.mint(68692219213121667537675943993034658256534085966823702, 312562089476538195);
        _positionHandler.redeemPositions(14346285029390138384631699352851716037838873523252820863546, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 156099301165664793782770725300034911992745565612292730719535759193816917);
        _positionHandler.failed();
        _positionHandler.moveLiquidity(3124, 4851, 22482, 489, 12560);
        _positionHandler.failed();
        _positionHandler.failed();
        _positionHandler.redeemPositions(12847, 1716, 21792638192227207103739660380579104546232133259664619746653999669489792464176, 6416);
        _positionHandler.failed();
        _positionHandler.mint(1, 1);
        _positionHandler.burn(429855229349693967633032639264591, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0, 16061636408720604028163146864844242179959313271462038759);
        _positionHandler.memorializePositions(1000000000000000000000000000, 2339, 9277, 2979);
        _positionHandler.failed();
        _positionHandler.moveLiquidity(1126936726725513634974948946146229558794440522269778954941252072750, 28213197928202789385986111147974297715344406983, 0, 1078163238702153671724735140934660154334823619509725521693, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _positionHandler.memorializePositions(218844288525098671251665, 1, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _positionHandler.burn(7059, 6750, 15855, 2093);
        _positionHandler.redeemPositions(18729, 617, 21015, 14643);
        _positionHandler.moveLiquidity(558, 0, 11493693556659833093547598989650493235947229407, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 21934937701560087003712);
        _positionHandler.mint(1135715274316739321105, 23206);
        _positionHandler.redeemPositions(15334, 3730, 31354931781638678607228669297131712859107492772550336241160036866987736981860, 2012);

        invariant_positions_PM1_PM2_PM3();
    }


    // assertion check on depositTime -> positionManager takes on larger of the two depositTime's (it's current DT and the incoming pos DT)
    function test_regression_position_assertions() external {
        
        _positionHandler.redeemPositions(14305804179334726329087114711985529806684597589133, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _positionHandler.redeemPositions(15796477295184955704374920720797, 8371624407570958028199016842329852681, 415665569658864472013466984364553963913525434423794529513837676955108, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _positionHandler.burn(1, 0, 21220, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _positionHandler.redeemPositions(23121, 7032, 1209600, 56750200883517406918163409362901600125139979314138135292026435586444244246336);
        _positionHandler.mint(17499, 10155);
        _positionHandler.moveLiquidity(4204702690764076468, 49830487004238111081, 3, 8687554674969877, 34664948256017662264545053667706057584168120838401342);
        _positionHandler.burn(115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 25655664119351, 378440596);
        _positionHandler.burn(9170, 9504, 11036, 7293);
        _positionHandler.memorializePositions(51818345872077820903041, 8835932826797125445564909432711163860901660866650218491158279446532175, 0, 43692);
        _positionHandler.moveLiquidity(3233, 18341, 1300, 20191, 9673);

        invariant_positions_PM1_PM2_PM3();
    }


    function test_regression_position_PM2_1() external {
        _positionHandler.mint(13840, 6533);
        _positionHandler.redeemPositions(20893347623242005284621573233176425472191492931621662294445581855285746938414, 4668, 249, 3313);
        _positionHandler.burn(106160155011218672810293641622355669764959155203, 5522, 6204, 13310117884160603562225350139269278401977957428370674638691902160380855891484);
        _positionHandler.mint(9971, 18762);
        _positionHandler.moveLiquidity(4746, 45809833274545460487123239222682366952882889382523246407515296007456152700521, 14885, 14435506720187687976692190077864919062649980910355626804100643005278456306280, 569);
        _positionHandler.burn(5618, 3294, 1912023601, 2562);
        _positionHandler.redeemPositions(19238, 9370, 18471734244850835106, 3079);
        _positionHandler.memorializePositions(840358, 614555546558083013200530954309972982184, 3, 3);
        _positionHandler.mint(1336497562, 1);
        _positionHandler.moveLiquidity(2, 17729644, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1780470449382083675, 4500661183205373);

        invariant_positions_PM1_PM2_PM3();
    }

    function test_regression_PM2_2() external {
        _positionHandler.redeemPositions(3025, 6080, 5086, 69064799185578049928162507577850320714069641703745944312650055827195794732674);
        _positionHandler.memorializePositions(83432655750528826189938123470649849289913398, 47342, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 1914359238258985260305115291516);
        _positionHandler.mint(0, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _positionHandler.redeemPositions(0, 251587735425228951994560583717, 0, 814796085823627054357);
        _positionHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639934, 94458646023247094980210508097430099597791255713941721593);
        _positionHandler.burn(2, 128812301633031168244819496636531096630, 54560285418771898578153, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _positionHandler.moveLiquidity(2, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1, 1, 16482458);
        _positionHandler.burn(2694, 1221913943207264759036595977299, 19113, 24481779477797754811799548851326479703104086113172195246494668587412015886643);
        _positionHandler.burn(2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _positionHandler.redeemPositions(0, 7413805626748343619920391043, 150386923782054503303407770601037610373899200732399952156206643020965362, 120900543111660751);
        _positionHandler.redeemPositions(30227346354289516712800253757043461339716641700294196, 674502096198391694316949722119995662541, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 1132758169212807134889911836402520);
        _positionHandler.redeemPositions(115792089237316195423570985008687907853269984665640564039457584007913129639933, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 2);
        _positionHandler.burn(313828860859517646886425614636, 208145610429269588268786717871941251049199228446877892696424877907568733235, 455942413, 2);
        _positionHandler.burn(19986504, 2423591226355826423555756030845668, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _positionHandler.burn(1, 465288888898469935211527628026186267178198412320, 3, 482209135685696192055);
        _positionHandler.mint(119225955014423, 600936253367888098311270698540073182733605077834901);
        _positionHandler.burn(1837, 3758, 4879, 13114);
        _positionHandler.redeemPositions(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 3, 725406937207957973195478707487444742436477165056);
        _positionHandler.moveLiquidity(4658405713153015933137719, 838417, 59, 25831175927826091855814245548488793681463667893532830343974308118799, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _positionHandler.memorializePositions(12016, 6319, 6900, 8690);

        invariant_positions_PM1_PM2_PM3();
    }

    function test_regression_position_manager() external {
        _positionHandler.redeemPositions(79335468733065507138817566659594782917024872257218805, 1889027018179489664211573893, 43578107449528230070726540147644518395094194018887636259089111851, 0);

    }

}