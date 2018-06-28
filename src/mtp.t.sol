pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "ds-value/value.sol";
import 'ds-guard/guard.sol';

import "sai/tub.sol";
import "sai/tap.sol";

import "maker-otc/matching_market.sol";

import "./mtp.sol";

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

        gem.mint(10000 ether);
        sai.mint(1000000 ether);
    }

    function setupTub() {
        pip = new DSValue();
        pep = new DSValue();
        dad = new DSGuard();
        vox = new SaiVox(RAY);
        tub = new SaiTub(sai, sin, skr, gem, gov, pip, pep, vox, 0x123);
        tap = 0x456;
        tub.turn(tap);

        // gem price 435.97 USD
        tub.pip().poke(435970000000000000000);

        // gov price 483.88
        tub.pip().poke(483580000000000000000);

        //Permit tub to 'mint' and 'burn' SKR
        skr.setAuthority(dad);
        dad.permit(tub, skr, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, skr, bytes4(keccak256('burn(address,uint256)')));

        //Permit tub to 'mint' and 'burn' SAI
        sai.setAuthority(dad);
        dad.permit(tub, sai, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, sai, bytes4(keccak256('burn(address,uint256)')));

        //Allow tub to mint, burn, and transfer gem/skr without approval
        gem.approve(tub);
        skr.approve(tub);
        sai.approve(tub);

        tub.mold('cap', 1000000000 ether);

        assert(!tub.off());

    }

    function setupOtc() public {
        otc = new MatchingMarket(uint64(now + 1 weeks));
        otc.addTokenPairWhitelist(sai, gov);
        otc.addTokenPairWhitelist(sai, gem);
        sai.approve(otc, uint(-1));
        gem.approve(otc, uint(-1));
    }

    function setupMtp() public {
        mtp = new Mtp(
            OtcInterface(address(otc)),
            TubInterface(address(tub)));
        sai.approve(mtp, uint(-1));
    }

    function setUp() public {
        setupTokens();
        setupTub();
        setupOtc();
        setupMtp();
    }

    function testMarginTrade() {
        uint offerId = otc.offer(100 ether, gem, 50000 ether, sai, 0);
        assertEq(tub.ink(mtp.marginTrade(10 ether, 1 ether)), 0.02 ether);
        assertEq(tub.ink(mtp.marginTrade(10 ether, 1.5 ether)), 0.03 ether);
        assertEq(tub.ink(mtp.marginTrade(10 ether, 1.75 ether)), 0.035 ether);
        assertEq(tub.ink(mtp.marginTrade(10 ether, 2 ether)), 0.040 ether);
    }
}
