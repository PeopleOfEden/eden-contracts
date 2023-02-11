// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface INFTLocker {
    function locked(uint256) external view returns (LockedBalance memory);

    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    struct LockedBalance {
        int128 amount;
        uint256 end;
        uint256 start;
    }
}
