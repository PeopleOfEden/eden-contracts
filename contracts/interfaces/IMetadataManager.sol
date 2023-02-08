// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetadataManager {
    struct TraitData {
        uint8 gender; // 0 -> male, 1 -> female
        uint8 skin; // 0 -> fair, 1 -> brown, 2 -> dark .... etc
        uint256 dnaMetadata;
        // extra space for any extra metadata to be added in the future
        uint256[10] a;
    }

    struct LockData {
        uint256 lastRecordedMAHAX;
        uint256 lastEvolvedMAHAX;
        uint256 lastRecordedAt;
    }

    event TraitDataSet(address who, uint256 nftId, TraitData data);

    function canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) external returns (bool);
}
