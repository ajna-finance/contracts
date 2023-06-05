
pragma solidity 0.8.18;

import { RewardsInvariants } from "../../invariants/PositionsAndRewards/RewardsInvariants.t.sol";
import { PoolInfoUtils }     from 'src/PoolInfoUtils.sol';

import '@std/console.sol';

contract RegressionRewardsManager is RewardsInvariants {

    function setUp() public override { 
        super.setUp();
    }

    // Test was failing due to incorrect removal of local tracked positions(tokenIdsByBucketIndex, bucketIndexesWithPosition) in handlers
    // Fixed by not removing local tracked positions
    function test_regression_rewards_PM1_1() public {
        _rewardsHandler.unstake(156983341, 3, 1057, 627477641256361);
        _rewardsHandler.settleAuction(2108881198342615861856429474, 922394580216134598, 4169158839, 1000000019773478651);
        invariant_positions_PM1_PM2_PM3();
    }

    // Test was failing due to incorrect removal of local tracked positions(tokenIdsByBucketIndex, bucketIndexesWithPosition) in handlers
    // Fixed by not removing local tracked positions
    function test_regression_rewards_PM1_2() public {
        _rewardsHandler.addCollateral(378299828523348996450409252968204856717337200844620995950755116109442848, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 52986329559447389847739820276326448003115507778858588690614563138365, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.memorializePositions(2386297678015684371711534521507, 1, 2015255596877246640, 0);
        _rewardsHandler.moveLiquidity(999999999999999999999999999999999999999542348, 2634, 6160, 4579, 74058);
        invariant_positions_PM1_PM2_PM3();
    }

    // Test was failing due to incorrect removal of local tracked positions(tokenIdsByBucketIndex, bucketIndexesWithPosition) in handlers
    // Fixed by not removing local tracked positions
    function test_regression_rewards_PM1_3() public {
        _rewardsHandler.memorializePositions(1072697513541617411598352761547948569235246260453338, 49598781763341098132796575116941537, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 59786055813720421827623480119157950185156928336);
        _rewardsHandler.drawDebt(71602122977707056985766204553433920464603022469065, 0, 3);
        _rewardsHandler.settleAuction(1533, 6028992255037431023, 999999999999998827363045226813101730497689206, 3712);
        _rewardsHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639935, 14721144691130718757631011689447950991492275176685060291564256, false, 136782600565674582447300799997512602488616407787063657498, 12104321153503350510632448265168933687786653851546540372949180052575211);
        _rewardsHandler.unstake(5219408520630054730985988951364206956803005171136246340104521696738150, 2, 0, 7051491938468651247212916289972038814809873);
        _rewardsHandler.settleAuction(0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 120615857050623137463512130550262626813346106);
        invariant_positions_PM1_PM2_PM3();
    }

    function test_regression_rewards_PM1_4() public {
        _rewardsHandler.moveLiquidity(832921267658491751933537549, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 62241022956197145532, 1165012150, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639932, 108613063553696015935192567274231711586207468226993603118670370534031542, 2, 1);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 2, 3);
        _rewardsHandler.settleAuction(1694548149298356876485941302354, 9052, 1444291546717740702970, 1303240033616582679504132393648);
        _rewardsHandler.burn(0, 707668523430171576399252973860135329463494151705, 13231138491987546580, 3);
        invariant_positions_PM1_PM2_PM3();
    }

    // Invariant was failing when rewards cap is equal to zero
    // Fixed by updating invariants to run only when rewards cap is non zero
    function test_regression_rewards_RW1() public {
        invariant_rewards_RW1();
    }

    // Test was failing due to unbounded debt drawn in `_preUnstake`
    // Fixed by bounding amount to borrow
    function test_regression_evm_revert_1() public {
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

    // Test was failing due to insufficient user token balance for `addQuoteToken` in `_preMemorializePositions`
    // Fixed with adding minting required tokens before `addQuoteToken`.
    function test_regression_evm_revert_2() public {
        _rewardsHandler.redeemPositions(535, 10526, 16402, 90638196);
        _rewardsHandler.moveQuoteToken(3, 3, 3665933105380066469, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 35609320936341689682324970775);
        _rewardsHandler.kickWithDeposit(65195123838887638071598468995195715179071041842210505440218069543269527898574, 1428, 1550);
        _rewardsHandler.updateExchangeRate(3324, 3433, 385);
        _rewardsHandler.removeQuoteToken(487993211956248337274085963929265840000354071708865988088685578811819, 8714694397591072960002001972219030782403253520, 0, 0);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3, 3, 0);
        _rewardsHandler.addQuoteToken(8049702985159192133654841011926250176578891096284667148191654768576101, 420390974052856985135062265979816823871512, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 6168047604119363323178237637165700555180739052007127817776433423995137133826);
        _rewardsHandler.pledgeCollateral(38623724134600076305519407, 1, 42313782903);
        _rewardsHandler.takeAuction(2520288506, 56779, 10626, 2578);
        _rewardsHandler.updateExchangeRate(2374, 3180, 11271);
        _rewardsHandler.moveQuoteToken(3, 84452381279, 65209096465360247728023547148755401892588275436, 1, 97710781974409185143365462469280072552935020234615584635942788);
        _rewardsHandler.claimRewards(4219, 7299, 3792253, 3829);
    }

    // unstake is being called with a minAmount that exceeds the rewards available, causing revert
    // change was made in regression to handle this case
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

    // During this last moveLiquidity call the user gets more quote tokens worth of LP tokens than they had before
    function test_regression_PM_failure() external {
        _rewardsHandler.repayDebt(85714, 1049291847999068770, 999999999999999999999999628872336833145697942);
        _rewardsHandler.settleAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 36806208, 15184194898560474755071902858637273513435561597233554208311133688, 467793045980282819019245873531034252276885664851);
        _rewardsHandler.takeReserves(430754706367378, 137895823818768170443343531843552347803975, 136256767494531323);
        _rewardsHandler.removeQuoteToken(151907177410358060568159872791300321117419489937830, 7129107044982420534725125240530941606156790404561718416111313794090, 9379839670333585391370, 64411724624691339174378);
        _rewardsHandler.repayDebt(115792089237316195423570985008687907853269984665640564039457584007913129639933, 4761347487120837320733494601307653768982862843053132338897249261174, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.moveLiquidity(1387083372699602, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1, 19432349521828210006920603112382926535859550351439231094, 1);
        _rewardsHandler.takeReserves(115792089237316195423570985008687907853269984665640564039457584007913129639935, 28562572353266841739143693967402627296578365988173585532380692, 0);
        _rewardsHandler.removeCollateral(880053353375737921406212405707, 1753558590, 6280826978696699921318109415672827430264350217031853972826832132306719032380, 787979188955935138704416864067);
        _rewardsHandler.moveLiquidity(11088, 1034959661872260168, 999999999999999212021821301557602448736097220, 25426918372734382433143072945767633116982163690088039971661147586959577591865, 999999999999999999999999998999999856219412005);
    }

    // moveLiquidity() call moves deposit from above -> below the LUP causing a fee to be applied to the user, therefore a loss in QT
    function test_regression_moveliquidity_below_lup() external {
        _rewardsHandler.unstake(4735, 7947, 99648028073174186569406251043082614463523861559444314198794141049070931765266, 165);
        _rewardsHandler.memorializePositions(1017586779835017595, 2000093450358386131913319801132, 999999999999999994705800289221, 5936);
        _rewardsHandler.kickWithDeposit(0, 552702177486359210209998874773373639789414577510403177176780671, 1);
        _rewardsHandler.kickWithDeposit(5408465446957, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 1244705446892222810789723108370662428040158);
        _rewardsHandler.pledgeCollateral(17006067685850655253277243263894458277559455, 365821919836536381007791134, 3);
        _rewardsHandler.transferLps(1020398235799939978, 8615, 10094997325303278, 6365, 16905);
        _rewardsHandler.moveQuoteToken(31568984050285372419235475362633334556373463, 2459831956710974374263868230506844670431779539018807045, 5569725293573705060280053370462598629680698918, 3, 0);
        _rewardsHandler.drawDebt(2189769129255122063229251712703191878940949, 1, 30);
        _rewardsHandler.redeemPositions(4988, 1000000019294578543, 113393, 20000);
        _rewardsHandler.moveLiquidity(11546346822809939448153205354420218227887882771387, 17456495056515572411115147660, 182412808598764326152439106919570567805594493064808060386470, 55874229446601275, 34611500787879233737900);    
    }

    function test_regression_PM1_PM2_PM3_failure() external {
        _rewardsHandler.addQuoteToken(1000476160430240196, 31831819542854202372682438294297749483895311991281138887779537875208920731861, 1690250244645061953490579723838, 8303344632134790875350129671);
        _rewardsHandler.redeemPositions(24517164785660125111092467892090015256239780879372312856314705897654233071616, 789619793367986175384776327373, 17366, 27337330393966417869011597343142520438331591211099340735032445540394415961142);
        _rewardsHandler.mint(4918260799182, 7979);
        _rewardsHandler.addCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 3);
        _rewardsHandler.unstake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 541386860615883, 3, 1427594577268427);
        _rewardsHandler.repayDebt(3, 73, 14148592833);
        _rewardsHandler.withdrawBonds(408448193972491682247856759691, 6725156476034981825430803209361659548467896941475, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _rewardsHandler.burn(207659258550486295439876272535780992392904995291122705229127151, 747338929, 1252191612369811194685436, 1);
        _rewardsHandler.settleAuction(40898023934445005959403090083409155881516500501072076223, 14829255767842040071, 22556694249976650341045163634875596221258685026085348004092232963852919995373, 0);
        _rewardsHandler.kickWithDeposit(3, 1763503097380079097391449321238134748267573906097584829633224009446989852620, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _rewardsHandler.failed();
        _rewardsHandler.pledgeCollateral(992967362603883335031186827777494890596884348, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.moveLiquidity(1439924512892792038061585821476, 12312838412972807476774254, 1386973529615993967509458441, 3153442172782088538684911, 25874047955237976217666127598767369999822558723350386077928985570803529547776);

        invariant_positions_PM1_PM2_PM3();
    }

    // exchange rate is below one and a moveLiquidity() call occurs
    function test_regression_exchangerate_lt_one_failure() external {
        _rewardsHandler.settleAuction(1, 38076326081732675084782953958723025268483402, 32122014834284740581605218790860586945, 675323572528116699998584163938054267674059083708770338684825);
        _rewardsHandler.takeAuction(3187233434979664450766064117497382244786499427506246277958134435335, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 68185348, 0);
        _rewardsHandler.removeQuoteToken(9799774902, 0, 171307717744339938462212153344256080, 22090621942183459004431027189984935997454202251794379);
        _rewardsHandler.settleAuction(10469641420936113, 158810559950203569266889779145, 2729976800298283367181, 629830085692443228137978633631);
        _rewardsHandler.kickAuction(1999638989041095890000000, 2621683063801908884388370586075, 5202919328337784754771241, 1704327030);
        _rewardsHandler.transferLps(115792089237316195423570985008687907853269984665640564039457584007913129639934, 0, 16473, 1298950632239640199, 92988305527741837015515230);
        _rewardsHandler.addQuoteToken(4513829468825775442619016612, 119081395592772229137, 2956368200448621153724264764841, 43337887745458188956665754735863930);
        _rewardsHandler.redeemPositions(1280000, 107418549682317941, 373995538053150407541675996799144040378996115919481128822550428, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.moveLiquidity(67209037983603756736, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 107047380550, 251040383784310909950712987871787320169957089, 136465421231555);
        _rewardsHandler.burn(0, 215634488088281622713592282980500574552450094015166108001671516324248273978, 2872470631302225600444008164197436445, 3825369962689014919985865);
        _rewardsHandler.redeemPositions(9321565985916881685418690197371166789551668163901391336422536021610052010235, 1000001049598692774037881, 1000916926448247166, 1294903748407840);
        _rewardsHandler.memorializePositions(11357398784982391024848846139138331345877617925164801651509999164448020739, 129054800695, 2, 0);
        _rewardsHandler.unstake(1008040767152967082, 2705590298374864519261, 2711436202524373179865882211354132, 1058992097359326876866506180);
        _rewardsHandler.drawDebt(0, 2, 2);
        _rewardsHandler.settleAuction(3, 109119248607504264825921197422518323470603, 2736316384792465597, 12368015967168137);
        _rewardsHandler.kickWithDeposit(1, 34593728349238363, 2);
        _rewardsHandler.pledgeCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 2);
        _rewardsHandler.takeReserves(37288205583577963230409441522973702491285105267336919446, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 2);
        _rewardsHandler.redeemPositions(46789, 6151865526048672236676594, 9043006728606892937350259542, 93268112651994959075836677);
        _rewardsHandler.moveLiquidity(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3563135139286698066907701283845339, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1711, 0);
    }

    // exchange rate was less than one in fromBucket during `moveLiquidity()` call
    function test_regression_exchangerate_lt_one_unstake_failure() external {
        _rewardsHandler.addQuoteToken(6142020986804765534920167884740010286243484147097745265674427, 112422117, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _rewardsHandler.removeCollateral(10151503789076003424768351930, 50838311790159949733482050440261, 787978286748398677564101888697, 743157368739340183819239223268107466431333883452773104647798952518671555);
        _rewardsHandler.updateExchangeRate(21755610456008175749216891385815221667397636280908693792396899755901148039675, 76822710358333592680973548681291198, 183811652651622670286097901303322315169696013956957316331731965);
        _rewardsHandler.moveQuoteToken(3843466665413066001504591, 1000009389351870783, 1000172353696212579, 2796008107630611079450058960364, 10168864164675898312163);
        _rewardsHandler.moveLiquidity(673087759601966739507343763016554, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 2339943610295551416526796192911912414311026002620, 1767503704449485978933058571939541599529908587415055225570810956, 9446221296393433187709657992720367407411357294298157052447175);
        _rewardsHandler.stake(999999999999999505134320049118757567405586786, 1025431341927257246, 1090, 13569953566136947230136843);
        _rewardsHandler.moveQuoteToken(1051099440087016359, 1357438875313834074678021636760282066916630639717893146590321, 63313628, 84622650405653151060672, 28876);
        _rewardsHandler.bucketTake(7462, 1121098501725271973, false, 999999999999999999999989741489665556227804536, 442072679406687075418827994186);
        _rewardsHandler.moveLiquidity(0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 515992583720, 11542363425921008807915173674517106);
    }

    // auction was clearable when `moveLiquidity()` was called, which fired a revert
    function test_regression_auction_clearable_remove_collateral() external {
        _rewardsHandler.takeReserves(1033259874529284986, 115792089237316195423570985008687907853269984665640564039457584007913129537237, 999999999999999999999999999611297087410149302);
        _rewardsHandler.bucketTake(115792089237316195423570985008687907853269984665640564039457584007913129639932, 0, true, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 1);
        _rewardsHandler.settleAuction(1019166912441147606, 1174, 24356906371720, 1427315247291615855384771361467057592874190974);
        _rewardsHandler.drawDebt(31570870468988913, 2490457201062127395317721901417, 14518);
        _rewardsHandler.removeQuoteToken(234409660495649, 601338041799139892223226281710979, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 51209466403350773952498018);
        _rewardsHandler.removeCollateral(1615097416247525221325833769791620, 999999999999998491682012949797990382689794890, 72294939771647531696639626124859859519954417706042013154, 1123754474529168009989296);
        _rewardsHandler.addQuoteToken(0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1418766863689180288802735178388574160614681714182842545424322601317331241, 0);
        _rewardsHandler.burn(10779801302631984284074768919, 1022785462636254549, 4247197939956962367856295710228836, 714087046845131802724051059732250799440226582946566742486292756992468224);
        _rewardsHandler.settleAuction(44188076061165790147414944966563643572374763434799334, 1, 6140, 982305872882119302926935288339691246129501298);
        _rewardsHandler.failed();
        _rewardsHandler.redeemPositions(115792089237316195423570985008687907853269984665640564039457584007913129639934, 1, 0, 1373087264969562284412462993767160637254468276739905307938530638280854638702);
        _rewardsHandler.pledgeCollateral(10321692057145851776062997, 45715379632908488147290369180827577791327034825339732187105428425706, 73584310749102695099025849803685991935361634);
        _rewardsHandler.moveQuoteToken(267424702347976937182244333, 53012, 1000122761636267185545584328894, 81844228617571507568624913, 2091433423541324315018709);
        _rewardsHandler.memorializePositions(4341569243600918031477893648, 1037146955303444803059178, 541740178036862, 1079117209305474618);
        _rewardsHandler.moveLiquidity(7990221475142856060836580, 5177379241789726416494109766258664604084660827937056770440668685154449638506, 270858793106233, 255697520996289263807310886, 4554);
    } 

    // underflow occurs on kick with Deposit due to round up occuring on the amount being removed from bucket
    function test_regression_kick_deposit_underflow() external {
        _rewardsHandler.claimRewards(115792089237316195423570985008687907853269984665640564039457584007913129639933, 486888075223510502299880936499251496488108390102993365331518154575959314103, 1489390063300625330233647743808860618285793249553177794776030333650229253556, 29413051449830420745080834496160737679746193111333313068326);
        _rewardsHandler.takeAuction(2000097453768943289819883643139, 1616, 9008, 2957522668165515327594480);
        _rewardsHandler.kickAuction(1023868299540571449491438, 2726, 3501, 1009546288143049196);
        _rewardsHandler.claimRewards(1850558667714835415003, 1128770330214, 48160424827244602174656651208212101506580, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.memorializePositions(2706256741681, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 0, 1224263559891519537412449982749693535319617589850332219938434821323);
        _rewardsHandler.kickAuction(2470057927126901389325412029621991572541444590040210706345694, 33212171733138561367109746153438995283000410403806989, 1143982811769352536641977506, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.addQuoteToken(11577, 2847, 701077953563936355129549681402475369359939627904709959917807724349081600, 6164);
        _rewardsHandler.mint(7455, 2274);
        _rewardsHandler.transferLps(3, 461323124985628625982, 3, 2265109234892451242814665907719473205880324711447657612395270, 36536442103629333036112242276175423646850388752964235954199714605113762301);
        _rewardsHandler.addCollateral(4807, 1257702269788440403102767606588, 10232361733685599944417, 8154);
        _rewardsHandler.moveLiquidity(1147643, 1101373970, 1, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _rewardsHandler.redeemPositions(715216745373273013565709474193709288265853036742499324291033262974521344, 925844451104042264560, 21216664920724276219251928893592593152072674630296951273414530379050570789349, 64994818096056336519112112386345118349558865048523329927782158963716200486113);
        _rewardsHandler.addCollateral(115792089237316195423570985008687907853269984665640564039457584007913129639934, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        _rewardsHandler.drawDebt(7803620494871325091384326, 1000000000005890305, 808187899175442127626759093647);
        _rewardsHandler.stake(1881897373701350, 1, 384457493842895898324057, 2);
        _rewardsHandler.kickAuction(1801888015, 36313972, 14589, 68230236911552087964619588008895983939113692817643498711581573912769382961420);
        _rewardsHandler.kickWithDeposit(3409291658389088656420401948375478879628336006312790484, 256489454668391, 264957533719095533849934255388);
    }


    // called takeReserves() when claimable reserves we're 0
    // fixed by switching from poolInfo.claimableReserves to _pool.reservesInfo()
    function test_regression_takereserves_no_claimable() external {
        _rewardsHandler.settleAuction(2, 3, 132571599922733151315276632984852300695962190184833433609822587845, 7127747531336);
        _rewardsHandler.failed();
        _rewardsHandler.pledgeCollateral(66498430692251244700, 1672526787, 999118417682487042682458556356);
        _rewardsHandler.settleAuction(102521875, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 2);
        _rewardsHandler.redeemPositions(0, 11874544000691612616189791308069964024776658688403726762, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _rewardsHandler.moveLiquidity(6932062779809046417357379434, 37304063095178465963, 289377204519251903, 24040659239847326449, 688903335135867866827970099664435153097141537805976741866417852208381952);
        _rewardsHandler.settleAuction(86639131860678742534809729831583343741269560864832321, 261140637, 18623697431831025536282119954975103467560305081672865, 18753717689854910664818243334489713190658697158135381);
        _rewardsHandler.moveLiquidity(688023305723199887936675774367107725948935104557465010923465143476322304, 426, 1361140653919103091484439143, 2492532610214694144077601771204, 1690059365);
        _rewardsHandler.removeCollateral(3, 75640118, 25456, 2);
        _rewardsHandler.stake(1201518266017002700145955555, 422051400149996, 191695523226259206952824982, 2575958376257460112331288247217);
        _rewardsHandler.removeCollateral(1724406295, 1153800818710038190908366, 198135760955974969122979112, 4072468695723038050466180656348448601624931627598867728374067772641581);
        _rewardsHandler.moveQuoteToken(1, 2, 7848862956757903893727, 108398233646184752124495509729309782170036195843104530456166511127401848014, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.kickAuction(1033780344472464085003, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 3, 4939129467716821333159227066);
        _rewardsHandler.memorializePositions(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 5339231111427732, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        _rewardsHandler.takeAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 49134859377105172171787763664088172754470175);
        _rewardsHandler.takeReserves(1000017062814174578, 695225158368402414621475732431414969707809712405441717937557041383099862, 1000099679120030632);
        _rewardsHandler.updateExchangeRate(1798084723794266922073360424201, 1000261123000933782, 1010104555201180320207069905273);
        _rewardsHandler.kickReserveAuction(14193, 4151);
        _rewardsHandler.claimRewards(84674527179871518692009907151225958831784072125472174554, 1123074827467033894904599425374, 0, 2);
    }

    // the rewards manager took ownership over the position NFT on stake
    // fixed in invariants tests by transfering positon NFT ownership to and from rewards on stake and unstake
    function test_regression_rewardsmanager_transfer_position_ownership() external {
        _rewardsHandler.redeemPositions(1513, 5414, 496, 2041);
        _rewardsHandler.moveLiquidity(1634580778705039759, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 3513140137853878345040965, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 6059353902491193986166404361793496);
        _rewardsHandler.takeAuction(20887, 7435, 2230322682, 5173);
        _rewardsHandler.removeQuoteToken(1, 37847095259185386235427787, 7586404791082, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        _rewardsHandler.kickReserveAuction(746270214, 3227);
        _rewardsHandler.claimRewards(3, 17838572802108205165768007139310483904447158906777650273909618150730155082, 179308467167974215120170861599730499666095743876089926251458944458077, 3);
        _rewardsHandler.kickAuction(115792089237316195423570985008687907853269984665640564039457584007913129639933, 3, 410137998186978556584901507876419312185968499332529, 0);
        _rewardsHandler.repayDebt(17165, 29, 4926);
        _rewardsHandler.redeemPositions(10181896186129835628862076, 4191, 2070, 4316);
        _rewardsHandler.unstake(2, 721416428842444814, 1, 1);
        _rewardsHandler.bucketTake(1701628611252955073601757907075824586952502043588380, 9931050451872161232934786702827793159570303822, true, 2925965874111818002623246439633594772, 3);
        _rewardsHandler.bucketTake(2, 15470539950385543111949808932971047871463497008525518386, false, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 1);
        _rewardsHandler.redeemPositions(115792089237316195423570985008687907853269984665640564039457584007913129639933, 2652132885321220255, 2, 1557926034);
    }
}
