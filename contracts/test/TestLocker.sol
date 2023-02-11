// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {INFTLocker} from "../interfaces/INFTLocker.sol";

contract TestLocker is INFTLocker {
    LockedBalance public lock;
    address public who;

    constructor(LockedBalance memory _lock) {
        lock = _lock;
    }

    function locked(uint256 id) external view returns (LockedBalance memory) {
        if (id == 0) return lock;
        return LockedBalance({amount: 0, end: 0, start: 0});
    }

    function ownerOf(uint256 id) external view returns (address owner) {
        if (id == 0) return who;
        return address(0);
    }
}
