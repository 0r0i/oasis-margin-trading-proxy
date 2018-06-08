pragma solidity ^0.4.23;

import "ds-test/test.sol";

import "./Mtc.sol";

contract MtcTest is DSTest {
    Mtc mtc;

    function setUp() public {
        mtc = new Mtc();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
