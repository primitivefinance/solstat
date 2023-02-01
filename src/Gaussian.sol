// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import "./Units.sol";


/**
 * @title Gaussian Math Library.
 * @author @alexangelj
 * @custom:coauthor @0xjepsen
 * @custom:coauthor @autoparallel
 *
 * @notice Models the normal distribution using the special Complimentary Error Function.
 *
 * @dev Only implements a distribution with mean (µ) = 0 and variance (σ) = 1.
 * Uses Numerical Recipes as a framework and reference C implemenation.
 * Numerical Recipes cites the original textbook written by Abramowitz and Stegun,
 * "Handbook of Mathematical Functions", which should be read to understand these
 * special functions and the implications of their numerical approximations.
 *
 * @custom:source Handbook of Mathematical Functions https://personal.math.ubc.ca/~cbm/aands/abramowitz_and_stegun.pdf.
 * @custom:source Numerical Recipes https://e-maxx.ru/bookz/files/numerical_recipes.pdf.
 * @custom:source todo: add source to rebuild constants.
 */
library Gaussian {
    using {muliWad, diviWad} for int256;

    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    
    error Infinity();
    error NegativeInfinity();

    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;


    /* int256 internal constant NUMERATOR_00 = int(0.49999999999999999811 ether);
    int256 internal constant NUMERATOR_01 = int(0.24263677400718738228 ether);
    int256 internal constant NUMERATOR_02 = -int(0.011648856042907906234 ether);
    int256 internal constant NUMERATOR_03 = -int(0.0097734960609453905318 ether);
    int256 internal constant NUMERATOR_04 = int(0.0041663305946462107851 ether);
    int256 internal constant NUMERATOR_05 = int(0.00024900492198452145059 ether);
    int256 internal constant NUMERATOR_06 = -int(0.00049474280263240618016 ether);
    int256 internal constant NUMERATOR_07 = -int(0.000071084638672424818163 ether);

    int256 internal constant DENOMINATOR_00 = -int(0.31261101278849232898 ether);
    int256 internal constant DENOMINATOR_01 = int(0.22612978855520117181 ether);
    int256 internal constant DENOMINATOR_02 = -int(0.066991699017824244845 ether);
    int256 internal constant DENOMINATOR_03 = int(0.020213053491913735237 ether);
    int256 internal constant DENOMINATOR_04 = -int(0.0055058768828928720853 ether);
    int256 internal constant DENOMINATOR_05 = int(0.00073065245498787981449 ether);
    int256 internal constant DENOMINATOR_06 = -int(0.00017319276451799988894 ether); */

    int256 internal constant NUMERATOR_00 = int( 0.499999999999999998 ether);
    int256 internal constant NUMERATOR_01 = int( 0.242636774007187382 ether);
    int256 internal constant NUMERATOR_02 = -int(0.011648856042907906 ether);
    int256 internal constant NUMERATOR_03 = -int(0.009773496060945390 ether);
    int256 internal constant NUMERATOR_04 = int( 0.004166330594646210 ether);
    int256 internal constant NUMERATOR_05 = int( 0.000249004921984521 ether);
    int256 internal constant NUMERATOR_06 = -int(0.000494742802632406 ether);
    int256 internal constant NUMERATOR_07 = -int(0.000071084638672424 ether);

    int256 internal constant DENOMINATOR_00 = -int(0.312611012788492328 ether);
    int256 internal constant DENOMINATOR_01 = int( 0.226129788555201171 ether);
    int256 internal constant DENOMINATOR_02 = -int(0.066991699017824244 ether);
    int256 internal constant DENOMINATOR_03 = int( 0.020213053491913735 ether);
    int256 internal constant DENOMINATOR_04 = -int(0.005505876882892872 ether);
    int256 internal constant DENOMINATOR_05 = int( 0.000730652454987879 ether);
    int256 internal constant DENOMINATOR_06 = -int(0.000173192764517999 ether);

    /**
        InverseCDF from 0.1 to 0.2
    (-3.1074230417999706210 
    - 596.46453194334818907 x 
    - 20126.909407388774404 x^2 
    - 157108.30640473029513 x^3 
    - 39348.723211892459912 x^4 
    + 981117.49161432863693 x^5 
    - 17931.208321030328917 x^6 
    - 377476.14698726339552 x^7)
    /
    (1.0000000000000000000 
    + 254.76193378669431529 x 
    + 11434.641049349157368 x^2 
    + 139433.55513675141158 x^3 
    + 442892.66768187718181 x^4 
    - 3117.1340524618763939 x^5 
    - 451151.33292991962878 x^6 
    + 55212.956626133777847 x^7)
    
     */

    
    int256 internal constant INV_NUMERATOR_00 = -int(3.1074230417999706210 ether); 
    int256 internal constant INV_NUMERATOR_01 = -int(596.46453194334818907 ether);
    int256 internal constant INV_NUMERATOR_02 = -int(20126.909407388774404 ether);
    int256 internal constant INV_NUMERATOR_03 = -int(157108.30640473029513 ether);
    int256 internal constant INV_NUMERATOR_04 = -int(39348.723211892459912 ether);
    int256 internal constant INV_NUMERATOR_05 = int(981117.49161432863693 ether);
    int256 internal constant INV_NUMERATOR_06 = -int(17931.208321030328917 ether);
    int256 internal constant INV_NUMERATOR_07 = -int(377476.14698726339552 ether);
    
    int256 internal constant INV_DENOMINATOR_00 = int(1.0000000000000000000 ether);
    int256 internal constant INV_DENOMINATOR_01 = int(254.76193378669431529 ether);
    int256 internal constant INV_DENOMINATOR_02 = int(11434.641049349157368 ether); 
    int256 internal constant INV_DENOMINATOR_03 = int(139433.55513675141158 ether);
    int256 internal constant INV_DENOMINATOR_04 = int(442892.66768187718181 ether);
    int256 internal constant INV_DENOMINATOR_05 = -int(3117.1340524618763939 ether); 
    int256 internal constant INV_DENOMINATOR_06 = -int(451151.33292991962878 ether);
    int256 internal constant INV_DENOMINATOR_07 = int(55212.956626133777847 ether);

    // inv 0.75 - 0.85
    /**
        (-2.02604513925351989985880130920 + 
   4.28999395020934118589462912580 x + 
   14.5480081980296701824482561013 x^2 - 
   57.1696548950579039839497046468 x^3 + 
   72.8466594526636446362594157259 x^4 - 
   42.1963609849073308181403680993 x^5 + 
   10.2569907660843219677765013424 x^6 - 
   0.549419488133939769312695313109 x^7)/(1 + 
   3.64401117555767906275746433157 x - 
   20.2533246241467023792545425657 x^2 + 
   27.2003754261053881599008229390 x^3 - 
   10.2005134346788042658233322718 x^4 - 
   5.36414947973099141136903492269 x^5 + 
   4.94135098022776664535186706887 x^6 - 
   0.967692771930615895825880268929 x^7)
     */
    int256 internal constant INV_75_85_NUMERATOR_00 = -int(2.026045139253519899 ether); 
    int256 internal constant INV_75_85_NUMERATOR_01 = int(4.289993950209341185 ether); 
    int256 internal constant INV_75_85_NUMERATOR_02 = int(14.548008198029670182 ether);  
    int256 internal constant INV_75_85_NUMERATOR_03 = -int(57.169654895057903983 ether);  
    int256 internal constant INV_75_85_NUMERATOR_04 = int(72.846659452663644636 ether);
    int256 internal constant INV_75_85_NUMERATOR_05 = -int(42.196360984907330818 ether); 
    int256 internal constant INV_75_85_NUMERATOR_06 = int(10.256990766084321967 ether); 
    int256 internal constant INV_75_85_NUMERATOR_07 = -int(0.549419488133939769 ether); 
   
   
   int256 internal constant INV_75_85_DENOMINATOR_00 = int(1 ether);
   int256 internal constant INV_75_85_DENOMINATOR_01 = int(3.644011175557679062 ether);  
   int256 internal constant INV_75_85_DENOMINATOR_02 = -int(20.253324624146702379 ether);
   int256 internal constant INV_75_85_DENOMINATOR_03 = int(27.200375426105388159 ether); 
   int256 internal constant INV_75_85_DENOMINATOR_04 = -int(10.200513434678804265 ether); 
   int256 internal constant INV_75_85_DENOMINATOR_05 = -int(5.364149479730991411 ether); 
   int256 internal constant INV_75_85_DENOMINATOR_06 = int(4.941350980227766645 ether); 
   int256 internal constant INV_75_85_DENOMINATOR_07 = -int(0.967692771930615895 ether); 


    int internal constant D_CONDITIONAL = 8.75729 ether;
    int internal constant D_0 = 3 ether;
    int internal constant D_1 = 6 ether;
    int internal constant D_2 = 9 ether;

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     *
     * @dev 
     *
     * We want to achieve an approximation for the Gaussian CDF with maximum error of 1e-18. Note that we
     * can use some symmetries to help us out. Remember, domain for Φ is all real numbers.
     * 
     * Notice that the Gaussian CDF satisfies Φ (- x )  1 - Φ ( x ) so we only need to form an approximation on
     * [ 0, ∞) .
     *
     * Furthermore, the CDF will be within 1e-18 of 1 when:
     * In[12] := N[InverseCDF[NormalDistribution[0, 1], 1 - 10 ^ (- 18)]]
     * Out[12] = 8.75729
     * 
     * We can approximate on the domain [ 0, 8.76 ] and have a conditional for when x > 8.76.
     * Let us subdivide this domain into 3 regions for sake of ease and just take D0  [ 0, 3 ], D1  ( 3, 6 ] ,
     * and D2  ( 6, 9 ] .
     * 
     * @custom:error 1e-18
     * @custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     * @custom:source @autoparallel
     */
    function cdf(int256 x) internal pure returns (int256 z) {
        int input = x; // keep the sign to check for later
        assembly {
            if lt(input, 0) {
                x := add(not(x), 1)
            }
        }

        // x > 0, since we took the absolute value above.
        if(x <= D_0) {
            z = _cdf_D_0(x);
        } else if (x <= D_1 && x > D_0) {
            z = _cdf_D_1(x);
        } else if (x <= D_CONDITIONAL && x > D_1) {
            z = _cdf_D_2(x);
        }  else {
            // x > D_CONDITIONAL
            z = ONE;
        }

        if(input < 0) z = ONE - z;
    }

/**
    int256 internal constant CDF_D0_NUM_00 = int(0.5000000000001512 ether);
int256 internal constant CDF_D0_NUM_01 = int(0.34619111068328146 ether);
int256 internal constant CDF_D0_NUM_02 = int(0.07343934152199676 ether);
int256 internal constant CDF_D0_NUM_03 = int(0.015005438621349508 ether);
int256 internal constant CDF_D0_NUM_04 = int(0.010497078168526857 ether);
int256 internal constant CDF_D0_NUM_05 = int(0.0031569901243625985 ether);
int256 internal constant CDF_D0_NUM_06 = int(0.0002523140051506348 ether);
int256 internal constant CDF_D0_NUM_07 = int(0.00003443528672881722 ether);
int256 internal constant CDF_D0_NUM_08 = int(0.000032150948703319105 ether);

int256 internal constant CDF_D0_DEN_00 = int(1 ether); 
int256 internal constant CDF_D0_DEN_01 = -int(0.10550233937600184 ether);
int256 internal constant CDF_D0_DEN_02 = int(0.23105736876384456 ether);
int256 internal constant CDF_D0_DEN_03 = -int(0.021365443736554336 ether);
int256 internal constant CDF_D0_DEN_04 = int(0.024011354713038002 ether);
int256 internal constant CDF_D0_DEN_05 = -int(0.0020645098335569417 ether);
int256 internal constant CDF_D0_DEN_06 = int(0.001413211356113515 ether);
int256 internal constant CDF_D0_DEN_07 = -int(0.00009646880796650478 ether);
int256 internal constant CDF_D0_DEN_08 = int(0.000038100614896736235 ether);

 */

    
int256 internal constant CDF_D0_NUM_00 = int( 0.5000000000001512 ether);
int256 internal constant CDF_D0_NUM_01 = int( 0.34619111068328146 ether);
int256 internal constant CDF_D0_NUM_02 = int( 0.07343934152199676 ether);
int256 internal constant CDF_D0_NUM_03 = int( 0.015005438621349508 ether);
int256 internal constant CDF_D0_NUM_04 = int( 0.010497078168526857 ether);
int256 internal constant CDF_D0_NUM_05 = int( 0.003156990124362598 ether);
int256 internal constant CDF_D0_NUM_06 = int( 0.000252314005150634 ether);
int256 internal constant CDF_D0_NUM_07 = int( 0.000034435286728817 ether);
int256 internal constant CDF_D0_NUM_08 = int( 0.000032150948703319 ether);

int256 internal constant CDF_D0_DEN_00 = int( 1 ether); 
int256 internal constant CDF_D0_DEN_01 = -int(0.10550233937600184 ether);
int256 internal constant CDF_D0_DEN_02 = int( 0.23105736876384456 ether);
int256 internal constant CDF_D0_DEN_03 = -int(0.021365443736554336 ether);
int256 internal constant CDF_D0_DEN_04 = int( 0.024011354713038002 ether);
int256 internal constant CDF_D0_DEN_05 = -int(0.002064509833556941 ether);
int256 internal constant CDF_D0_DEN_06 = int( 0.001413211356113515 ether);
int256 internal constant CDF_D0_DEN_07 = -int(0.000096468807966504 ether);
int256 internal constant CDF_D0_DEN_08 = int( 0.000038100614896736 ether);

    function _cdf_D_0(int x) internal pure returns (int z) {
        {
                z = CDF_D0_NUM_00 + CDF_D0_NUM_01.muliWad(x);
                z = z + CDF_D0_NUM_02.muliWad(x.powWad(2 ether));
                z = z + CDF_D0_NUM_03.muliWad(x.powWad(3 ether));
                z = z + CDF_D0_NUM_04.muliWad(x.powWad(4 ether));
                z = z + CDF_D0_NUM_05.muliWad(x.powWad(5 ether));
                z = z + CDF_D0_NUM_06.muliWad(x.powWad(6 ether));
                z = z + CDF_D0_NUM_07.muliWad(x.powWad(7 ether));
                z = z + CDF_D0_NUM_08.muliWad(x.powWad(8 ether));
            }

            int256 denom = CDF_D0_DEN_00 + CDF_D0_DEN_01.muliWad(x);
            {
                denom = denom + CDF_D0_DEN_02.muliWad(x.powWad(2 ether));
                denom = denom + CDF_D0_DEN_03.muliWad(x.powWad(3 ether));
                denom = denom + CDF_D0_DEN_04.muliWad(x.powWad(4 ether));
                denom = denom + CDF_D0_DEN_05.muliWad(x.powWad(5 ether));
                denom = denom + CDF_D0_DEN_06.muliWad(x.powWad(6 ether));
                denom = denom + CDF_D0_DEN_07.muliWad(x.powWad(7 ether));
                denom = denom + CDF_D0_DEN_08.muliWad(x.powWad(8 ether));
            }

            z = z.diviWad(denom);
    }

    /**
    
        int256 internal constant CDF_D1_NUM_00 = int(0.9056608133562424 ether);
int256 internal constant CDF_D1_NUM_01 = -int(2.235698942833327  ether);
int256 internal constant CDF_D1_NUM_02 = int(2.8122029638271755 ether);
int256 internal constant CDF_D1_NUM_03 = -int(2.0227711585027435 ether);
int256 internal constant CDF_D1_NUM_04 = int(0.9315063099190092 ether);
int256 internal constant CDF_D1_NUM_05 = -int(0.2796800134653801 ether);
int256 internal constant CDF_D1_NUM_06 = int(0.05430662321946488 ether);
int256 internal constant CDF_D1_NUM_07 = -int(0.006260049401674065 ether);
int256 internal constant CDF_D1_NUM_08 = int(0.00034397631639012267 ether);

int256 internal constant CDF_D1_DEN_00 = int(1 ether); 
int256 internal constant CDF_D1_DEN_01 = -int(2.352305698358789 ether);
int256 internal constant CDF_D1_DEN_02 = int(2.875623930902345 ether);
int256 internal constant CDF_D1_DEN_03 = -int(2.042593118041022 ether);
int256 internal constant CDF_D1_DEN_04 = int(0.9353996617067968 ether);
int256 internal constant CDF_D1_DEN_05 = -int(0.2801720558155541 ether);
int256 internal constant CDF_D1_DEN_06 = int(0.05434569108170826 ether);
int256 internal constant CDF_D1_DEN_07 = -int(0.006261830926369743 ether);
int256 internal constant CDF_D1_DEN_08 = int(0.00034401203285696437 ether);
    
     */

int256 internal constant CDF_D1_NUM_00 = int( 0.9056608133562424 ether);
int256 internal constant CDF_D1_NUM_01 = -int(2.235698942833327  ether);
int256 internal constant CDF_D1_NUM_02 = int( 2.8122029638271755 ether);
int256 internal constant CDF_D1_NUM_03 = -int(2.0227711585027435 ether);
int256 internal constant CDF_D1_NUM_04 = int( 0.9315063099190092 ether);
int256 internal constant CDF_D1_NUM_05 = -int(0.2796800134653801 ether);
int256 internal constant CDF_D1_NUM_06 = int( 0.05430662321946488 ether);
int256 internal constant CDF_D1_NUM_07 = -int(0.006260049401674065 ether);
int256 internal constant CDF_D1_NUM_08 = int( 0.000343976316390122 ether);

int256 internal constant CDF_D1_DEN_00 = int( 1 ether); 
int256 internal constant CDF_D1_DEN_01 = -int(2.352305698358789 ether);
int256 internal constant CDF_D1_DEN_02 = int( 2.875623930902345 ether);
int256 internal constant CDF_D1_DEN_03 = -int(2.042593118041022 ether);
int256 internal constant CDF_D1_DEN_04 = int( 0.9353996617067968 ether);
int256 internal constant CDF_D1_DEN_05 = -int(0.2801720558155541 ether);
int256 internal constant CDF_D1_DEN_06 = int( 0.05434569108170826 ether);
int256 internal constant CDF_D1_DEN_07 = -int(0.006261830926369743 ether);
int256 internal constant CDF_D1_DEN_08 = int( 0.000344012032856964 ether);

    function _cdf_D_1(int x) internal pure returns (int z) {
        {
                z = CDF_D1_NUM_00 + CDF_D1_NUM_01.muliWad(x);
                z = z + CDF_D1_NUM_02.muliWad(x.powWad(2 ether));
                z = z + CDF_D1_NUM_03.muliWad(x.powWad(3 ether));
                z = z + CDF_D1_NUM_04.muliWad(x.powWad(4 ether));
                z = z + CDF_D1_NUM_05.muliWad(x.powWad(5 ether));
                z = z + CDF_D1_NUM_06.muliWad(x.powWad(6 ether));
                z = z + CDF_D1_NUM_07.muliWad(x.powWad(7 ether));
                z = z + CDF_D1_NUM_08.muliWad(x.powWad(8 ether));
            }

            int256 denom = CDF_D1_DEN_00 + CDF_D1_DEN_01.muliWad(x);
            {
                denom = denom + CDF_D1_DEN_02.muliWad(x.powWad(2 ether));
                denom = denom + CDF_D1_DEN_03.muliWad(x.powWad(3 ether));
                denom = denom + CDF_D1_DEN_04.muliWad(x.powWad(4 ether));
                denom = denom + CDF_D1_DEN_05.muliWad(x.powWad(5 ether));
                denom = denom + CDF_D1_DEN_06.muliWad(x.powWad(6 ether));
                denom = denom + CDF_D1_DEN_07.muliWad(x.powWad(7 ether));
                denom = denom + CDF_D1_DEN_08.muliWad(x.powWad(8 ether));
            }

            z = z.diviWad(denom);
    }

    /**
    
    int256 internal constant CDF_D2_NUM_00 = int(0.9999999999304509 ether);
int256 internal constant CDF_D2_NUM_01 = -int(1.386033834303907 ether);
int256 internal constant CDF_D2_NUM_02 = int(0.8430007490131848 ether);
int256 internal constant CDF_D2_NUM_03 = -int(0.29393310457954774 ether);
int256 internal constant CDF_D2_NUM_04 = int(0.0642790213358189 ether);
int256 internal constant CDF_D2_NUM_05 = -int(0.009030719766973058 ether);
int256 internal constant CDF_D2_NUM_06 = int(0.0007962701869917997 ether);
int256 internal constant CDF_D2_NUM_07 = -int(0.00004030360558414773 ether);
int256 internal constant CDF_D2_NUM_08 = int(0.0000008970178787849753 ether);

int256 internal constant CDF_D2_DEN_00 = int(1 ether); 
int256 internal constant CDF_D2_DEN_01 = -int(1.3860338343691025 ether);
int256 internal constant CDF_D2_DEN_02 = int(0.8430007490399601 ether);
int256 internal constant CDF_D2_DEN_03 = -int(0.29393310458583993 ether);
int256 internal constant CDF_D2_DEN_04 = int(0.06427902133674428 ether);
int256 internal constant CDF_D2_DEN_05 = -int( 0.009030719767060266 ether);
int256 internal constant CDF_D2_DEN_06 = int(0.0007962701869969425 ether);
int256 internal constant CDF_D2_DEN_07 = -int(0.00004030360558432123 ether);
int256 internal constant CDF_D2_DEN_08 = int(0.0000008970178787875392 ether);

     */

int256 internal constant CDF_D2_NUM_00 = int( 0.9999999999304509 ether);
int256 internal constant CDF_D2_NUM_01 = -int(1.386033834303907 ether);
int256 internal constant CDF_D2_NUM_02 = int( 0.8430007490131848 ether);
int256 internal constant CDF_D2_NUM_03 = -int(0.29393310457954774 ether);
int256 internal constant CDF_D2_NUM_04 = int( 0.0642790213358189 ether);
int256 internal constant CDF_D2_NUM_05 = -int(0.009030719766973058 ether);
int256 internal constant CDF_D2_NUM_06 = int( 0.000796270186991799 ether);
int256 internal constant CDF_D2_NUM_07 = -int(0.000040303605584147 ether);
int256 internal constant CDF_D2_NUM_08 = int( 0.000000897017878784 ether);

int256 internal constant CDF_D2_DEN_00 = int( 1 ether); 
int256 internal constant CDF_D2_DEN_01 = -int(1.3860338343691025 ether);
int256 internal constant CDF_D2_DEN_02 = int( 0.8430007490399601 ether);
int256 internal constant CDF_D2_DEN_03 = -int(0.29393310458583993 ether);
int256 internal constant CDF_D2_DEN_04 = int( 0.06427902133674428 ether);
int256 internal constant CDF_D2_DEN_05 = -int(0.009030719767060266 ether);
int256 internal constant CDF_D2_DEN_06 = int( 0.000796270186996942 ether);
int256 internal constant CDF_D2_DEN_07 = -int(0.000040303605584321 ether);
int256 internal constant CDF_D2_DEN_08 = int( 0.000000897017878787 ether);

    function _cdf_D_2(int x) internal pure returns (int z) {
        {
                z = CDF_D2_NUM_00 + CDF_D2_NUM_01.muliWad(x);
                z = z + CDF_D2_NUM_02.muliWad(x.powWad(2 ether));
                z = z + CDF_D2_NUM_03.muliWad(x.powWad(3 ether));
                z = z + CDF_D2_NUM_04.muliWad(x.powWad(4 ether));
                z = z + CDF_D2_NUM_05.muliWad(x.powWad(5 ether));
                z = z + CDF_D2_NUM_06.muliWad(x.powWad(6 ether));
                z = z + CDF_D2_NUM_07.muliWad(x.powWad(7 ether));
                z = z + CDF_D2_NUM_08.muliWad(x.powWad(8 ether));
            }

            int256 denom = CDF_D2_DEN_00 + CDF_D2_DEN_01.muliWad(x);
            {
                denom = denom + CDF_D2_DEN_02.muliWad(x.powWad(2 ether));
                denom = denom + CDF_D2_DEN_03.muliWad(x.powWad(3 ether));
                denom = denom + CDF_D2_DEN_04.muliWad(x.powWad(4 ether));
                denom = denom + CDF_D2_DEN_05.muliWad(x.powWad(5 ether));
                denom = denom + CDF_D2_DEN_06.muliWad(x.powWad(6 ether));
                denom = denom + CDF_D2_DEN_07.muliWad(x.powWad(7 ether));
                denom = denom + CDF_D2_DEN_08.muliWad(x.powWad(8 ether));
            }

            z = z.diviWad(denom);
    }


    function ppf(int x) internal pure returns(int z) {
        if(x >= ONE) revert Infinity();
        if(x <= 0) revert NegativeInfinity();
        
        int input;
        if(x >= 0.5 ether) {
            input = x;
            z = _ppf(input);
        } else {
            input = ONE - x;
            z = -_ppf(input);
        }
    }

int256 internal constant ICDF_NUM_00 = -int(2.1964156084677744 ether);
int256 internal constant ICDF_NUM_01 = -int(2.3818617473241472 ether);
int256 internal constant ICDF_NUM_02 = int(52.96704779216531 ether);
int256 internal constant ICDF_NUM_03 = -int(130.25644563937203 ether);
int256 internal constant ICDF_NUM_04 = int(118.19902763128829 ether);
int256 internal constant ICDF_NUM_05 = -int(15.516658888460118 ether);
int256 internal constant ICDF_NUM_06 = -int(42.26493060412894 ether);
int256 internal constant ICDF_NUM_07 = int(26.03404494904412 ether);
int256 internal constant ICDF_NUM_08 = -int(4.583636876567552 ether);

int256 internal constant ICDF_DEN_00 = int(1 ether); 
int256 internal constant ICDF_DEN_01 = int(8.816760515252659 ether);
int256 internal constant ICDF_DEN_02 = -int(31.70037391431139 ether);
int256 internal constant ICDF_DEN_03 = int(16.878862562528372 ether);
int256 internal constant ICDF_DEN_04 = int(44.08551098967766 ether);
int256 internal constant ICDF_DEN_05 = -int(69.64058923743971 ether);
int256 internal constant ICDF_DEN_06 = int(38.432479954587706 ether);
int256 internal constant ICDF_DEN_07 = -int(8.183187917767329 ether);
int256 internal constant ICDF_DEN_08 = int(0.3105935545639353 ether);

    function _ppf(int x) internal pure returns(int z) {
        {
                z = ICDF_NUM_00 + ICDF_NUM_01.muliWad(x);
                z = z + ICDF_NUM_02.muliWad(x.powWad(2 ether));
                z = z + ICDF_NUM_03.muliWad(x.powWad(3 ether));
                z = z + ICDF_NUM_04.muliWad(x.powWad(4 ether));
                z = z + ICDF_NUM_05.muliWad(x.powWad(5 ether));
                z = z + ICDF_NUM_06.muliWad(x.powWad(6 ether));
                z = z + ICDF_NUM_07.muliWad(x.powWad(7 ether));
                z = z + ICDF_NUM_08.muliWad(x.powWad(8 ether));
            }

            int256 denom = ICDF_DEN_00 + ICDF_DEN_01.muliWad(x);
            {
                denom = denom + ICDF_DEN_02.muliWad(x.powWad(2 ether));
                denom = denom + ICDF_DEN_03.muliWad(x.powWad(3 ether));
                denom = denom + ICDF_DEN_04.muliWad(x.powWad(4 ether));
                denom = denom + ICDF_DEN_05.muliWad(x.powWad(5 ether));
                denom = denom + ICDF_DEN_06.muliWad(x.powWad(6 ether));
                denom = denom + ICDF_DEN_07.muliWad(x.powWad(7 ether));
                denom = denom + ICDF_DEN_08.muliWad(x.powWad(8 ether));
            }

            z = z.diviWad(denom);
    }

    // old ====

    function _cdf(int256 x) internal pure returns (int256 z) {

            {
                z = NUMERATOR_00 + NUMERATOR_01.muliWad(x);
                z = z + NUMERATOR_02.muliWad(x.powWad(2 ether));
                z = z + NUMERATOR_03.muliWad(x.powWad(3 ether));
                z = z + NUMERATOR_04.muliWad(x.powWad(4 ether));
                z = z + NUMERATOR_05.muliWad(x.powWad(5 ether));
                z = z + NUMERATOR_06.muliWad(x.powWad(6 ether));
                z = z + NUMERATOR_07.muliWad(x.powWad(7 ether));
            }

            int256 denom = ONE + DENOMINATOR_00.muliWad(x);
            {
                denom = denom + DENOMINATOR_01.muliWad(x.powWad(2 ether));
                denom = denom + DENOMINATOR_02.muliWad(x.powWad(3 ether));
                denom = denom + DENOMINATOR_03.muliWad(x.powWad(4 ether));
                denom = denom + DENOMINATOR_04.muliWad(x.powWad(5 ether));
                denom = denom + DENOMINATOR_05.muliWad(x.powWad(6 ether));
                denom = denom + DENOMINATOR_06.muliWad(x.powWad(7 ether));
            }

            z = z.diviWad(denom);
    }

    // inv cdf 0.45 to 0.5
    /**
         (-2.32617831927582041 - 
    16.9320245015635808 x + 54.6144693202202685 x^2 - 
    2.58392793492210328 x^3 - 50.7792254964642328 x^4 + 
    20.3285064126982771 x^5)/(1.00000000000000000 + 
    17.0875273964305546 x + 5.23915275686175674 x^2 - 
    44.6865805174757853 x^3 + 22.3659233834186746 x^4 - 
    0.00811782582094392776 x^5)
    
     */

    int256 internal constant INV_45_55_NUMERATOR_00 = -int( 2.32617831927582041 ether);
    int256 internal constant INV_45_55_NUMERATOR_01 = -int(16.9320245015635808 ether);
    int256 internal constant INV_45_55_NUMERATOR_02 = int(54.6144693202202685  ether);
    int256 internal constant INV_45_55_NUMERATOR_03 = -int(2.58392793492210328  ether); 
    int256 internal constant INV_45_55_NUMERATOR_04 = -int(50.7792254964642328 ether);
    int256 internal constant INV_45_55_NUMERATOR_05 = int(20.3285064126982771  ether);
    
    int256 internal constant INV_45_55_DENOMINATOR_00 = int(1.00000000000000000 ether); 
    int256 internal constant INV_45_55_DENOMINATOR_01 = int(17.0875273964305546 ether);
    int256 internal constant INV_45_55_DENOMINATOR_02 = int(5.23915275686175674 ether);
    int256 internal constant INV_45_55_DENOMINATOR_03 = -int(44.6865805174757853 ether);
    int256 internal constant INV_45_55_DENOMINATOR_04 = int(22.3659233834186746 ether);
    int256 internal constant INV_45_55_DENOMINATOR_05 = -int(0.008117825820943927 ether);

    /**
     * @notice Approximation of the Percent Point Function.
     *
     * @dev Equal to `D(x)^(-1) = µ - σ√2(ierfc(2x))`.
     * Only computes ppf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:error todo: what is the minimum absolute error?
     * @custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     * @custom:source todo: approximation info from @autoparallel
     */
    function ppf_old(int x) internal pure returns (int z) {
        {

        if(x >= int(0.1 ether) && x <= int(0.2 ether)) {
            {
                z = INV_NUMERATOR_00 + INV_NUMERATOR_01.muliWad(x);
                z = z + INV_NUMERATOR_02.muliWad(x.powWad(2 ether));
                z = z + INV_NUMERATOR_03.muliWad(x.powWad(3 ether));
                z = z + INV_NUMERATOR_04.muliWad(x.powWad(4 ether));
                z = z + INV_NUMERATOR_05.muliWad(x.powWad(5 ether));
                z = z + INV_NUMERATOR_06.muliWad(x.powWad(6 ether));
                z = z + INV_NUMERATOR_07.muliWad(x.powWad(7 ether));
            }

            int256 denom = INV_DENOMINATOR_00 + INV_DENOMINATOR_01.muliWad(x);
            {
                denom = denom + INV_DENOMINATOR_02.muliWad(x.powWad(2 ether));
                denom = denom + INV_DENOMINATOR_03.muliWad(x.powWad(3 ether));
                denom = denom + INV_DENOMINATOR_04.muliWad(x.powWad(4 ether));
                denom = denom + INV_DENOMINATOR_05.muliWad(x.powWad(5 ether));
                denom = denom + INV_DENOMINATOR_06.muliWad(x.powWad(6 ether));
                denom = denom + INV_DENOMINATOR_07.muliWad(x.powWad(7 ether));
            }

            z = z.diviWad(denom);
        }
        }

        {
        if(x >= int(0.75 ether) && x <= int(0.85 ether)) {
            {
                z = INV_75_85_NUMERATOR_00 + INV_75_85_NUMERATOR_01.muliWad(x);
                z = z + INV_75_85_NUMERATOR_02.muliWad(x.powWad(2 ether));
                z = z + INV_75_85_NUMERATOR_03.muliWad(x.powWad(3 ether));
                z = z + INV_75_85_NUMERATOR_04.muliWad(x.powWad(4 ether));
                z = z + INV_75_85_NUMERATOR_05.muliWad(x.powWad(5 ether));
                z = z + INV_75_85_NUMERATOR_06.muliWad(x.powWad(6 ether));
                z = z + INV_75_85_NUMERATOR_07.muliWad(x.powWad(7 ether));
            }

            int256 denom = INV_75_85_DENOMINATOR_00 + INV_75_85_DENOMINATOR_01.muliWad(x);
            {
                denom = denom + INV_75_85_DENOMINATOR_02.muliWad(x.powWad(2 ether));
                denom = denom + INV_75_85_DENOMINATOR_03.muliWad(x.powWad(3 ether));
                denom = denom + INV_75_85_DENOMINATOR_04.muliWad(x.powWad(4 ether));
                denom = denom + INV_75_85_DENOMINATOR_05.muliWad(x.powWad(5 ether));
                denom = denom + INV_75_85_DENOMINATOR_06.muliWad(x.powWad(6 ether));
                denom = denom + INV_75_85_DENOMINATOR_07.muliWad(x.powWad(7 ether));
            }

            z = z.diviWad(denom);
        }
        }

        {
        if(x >= int(0.45 ether) && x <= int(0.55 ether)) {
            {
                z = INV_45_55_NUMERATOR_00 + INV_45_55_NUMERATOR_01.muliWad(x);
                z = z + INV_45_55_NUMERATOR_02.muliWad(x.powWad(2 ether));
                z = z + INV_45_55_NUMERATOR_03.muliWad(x.powWad(3 ether));
                z = z + INV_45_55_NUMERATOR_04.muliWad(x.powWad(4 ether));
                z = z + INV_45_55_NUMERATOR_05.muliWad(x.powWad(5 ether));
            }

            int256 denom = INV_45_55_DENOMINATOR_00 + INV_45_55_DENOMINATOR_01.muliWad(x);
            {
                denom = denom + INV_45_55_DENOMINATOR_02.muliWad(x.powWad(2 ether));
                denom = denom + INV_45_55_DENOMINATOR_03.muliWad(x.powWad(3 ether));
                denom = denom + INV_45_55_DENOMINATOR_04.muliWad(x.powWad(4 ether));
                denom = denom + INV_45_55_DENOMINATOR_05.muliWad(x.powWad(5 ether));
            }

            z = z.diviWad(denom);
        }
        }
    }

    /// todo: implement w/ approxes
    function pdf(int256 x) internal pure returns (int256 z) {
        z = x;
    }
}
