// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {INFTLocker} from "../interfaces/INFTLocker.sol";

/**
 * A test contract that gives a lock for nft id 1
 */
contract TestLocker is INFTLocker {
    LockedBalance public lock;
    address public who;

    constructor() {
        lock = LockedBalance({
            amount: 1000 * 1e18,
            end: block.timestamp + (86400 * 365), // 1 year lock
            start: block.timestamp
        });

        who = msg.sender;
    }

    function locked(uint256 id) external view returns (LockedBalance memory) {
        if (id == 1) return lock;
        return LockedBalance({amount: 0, end: 0, start: 0});
    }

    function ownerOf(uint256 id) external view returns (address owner) {
        if (id == 1) return who;
        return address(0);
    }

    function increaseLockAmount(int128 amt) external {
        lock.amount += amt;
    }
}
