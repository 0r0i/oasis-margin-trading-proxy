pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "ds-value/value.sol";
import 'ds-guard/guard.sol';

import "sai/tub.sol";
import "sai/tap.sol";

import "maker-otc/matching_market.sol";

import "./.sol";
//import "../lib/sai/lib/ds-value/src/value.sol";
//import "../lib/maker-otc/lib/ds-token/lib/ds-stop/lib/ds-note/lib/ds-test/src/test.sol";

contract MtpTest is DSTest, DSMath {

    Mtp mtp;

    //tokens
    DSToken sai;  // dai
    DSToken sin;  // debt, negative sai
    DSToken skr;  // peth
    DSToken gem;  // weth
    DSToken gov;  // mkr
    DSToken dgd;  // dgd


    // tup
    address tap;
    SaiTub  tub;
    SaiVox  vox;

    DSGuard dad;

    DSValue pip;
    DSValue pep;

    //otc
    MatchingMarket otc;

    function setupTokens() {
        sai = new DSToken("DAI");
        sin = new DSToken("SIN");
        skr = new DSToken("PETH");
        gem = new DSToken("WETH");
        gov = new DSToken("MKR");

        gem.mint(6 ether);

        //Verify initial token balances
        assertEq(gem.balanceOf(this), 6 ether);
        assertEq(gem.balanceOf(tub), 0 ether);
        assertEq(skr.totalSupply(), 0 ether);
    }

    function setupTub() {
        pip = new DSValue();
        pip = new DSValue();
        pep = new DSValue();
        dad = new DSGuard();
        vox = new SaiVox(RAY);
        tub = new SaiTub(sai, sin, skr, gem, gov, pip, pep, vox, 0x123);
        tap = 0x456;
        tub.turn(tap);


        //Set whitelist authority
        skr.setAuthority(dad);

        //Permit tub to 'mint' and 'burn' SKR
        dad.permit(tub, skr, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, skr, bytes4(keccak256('burn(address,uint256)')));

        //Allow tub to mint, burn, and transfer gem/skr without approval
        gem.approve(tub);
        skr.approve(tub);
        sai.approve(tub);

        assert(!tub.off());

    }

    function setupOtc() public {

        otc = new MatchingMarket(uint64(now + 1 weeks));

        otc.addTokenPairWhitelist(sai, gov);
    }

    function setUp() public {
        setupTokens();
        setupTub();
        setupOtc();
        mtp = new Mtp();
    }

    function testMarginTrage() {
        mtc.marginTrade(
            TubInterface(address(tub)),
            OtcInterface(address(otc)),
            1);
    }
}
