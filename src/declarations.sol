pragma solidity ^0.4.23;

contract OtcInterface {
    function getBuyAmount(address, address, uint) public returns (uint);
    function buyAllAmount(address, uint, address, uint) public returns (uint);
    function getPayAmount(address, address, uint) public returns (uint);
    function sellAllAmount(address, uint, address, uint) public returns (uint);
}

contract TokenInterface {
    function balanceOf(address) public returns (uint);
    function approve(address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function allowance(address src, address guy) public view returns (uint);
}

contract TubInterface {
    function open() public returns (bytes32);
    function join(uint) public;
    function lock(bytes32, uint) public;
    function draw(bytes32, uint) public;
    function give(bytes32, address) public;
    function gem() public returns (TokenInterface);
    function skr() public returns (TokenInterface);
    function sai() public returns (TokenInterface);
    function vox() public returns (VoxInterface);
    function mat() public pure returns (uint);
    function per() public pure returns (uint);
    function gap() public pure returns (uint);
    function pip() public returns (PipInterface);
    function ink(bytes32 cup) public view returns (uint);
}

contract VoxInterface {
    function par() public returns (uint);
}

contract PipInterface {
    function read() public returns (bytes32);
}
