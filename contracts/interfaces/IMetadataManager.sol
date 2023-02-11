// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetadataManager {
    struct TraitData {
        uint8 gender; // 0 -> unkown, 1 -> male, 2 -> female
        uint8 skin; // 0 -> unkown, 1 -> fair, 2 -> brown, 3 -> dark .... etc
        uint256 dnaMetadata;
        // mahax snapshot
        uint256 lastRecordedMAHAX;
        uint256 lastRecordedAt;
        // extra space for any extra metadata to be added in the future
        // uint256[10] a;
    }

    event TraitDataSet(address who, uint256 nftId, TraitData data);
    event NFTEvolved(
        address who,
        uint256 nftId,
        uint256 oldMAHAX,
        uint256 newMAHAX
    );

    event NFTHistoryOverrided(
        address who,
        uint256 nftId,
        uint256 overrideIndex
    );

    /// @notice anyone can initialize their traits if it hasn't been set already.
    function initTraits(uint256 nftId, TraitData memory data) external;

    /// @notice special trusted contracts can update traits on behalf of a NFT
    function setTrait(uint256 nftId, TraitData memory data) external;

    /// @notice evolve the traits of a NFT. callable only by the nft owner
    function evolve(uint256 nftId) external;

    function canNFTEvolve(uint256 nftId) external view returns (bool);

    function getLatestTraitData(
        uint256 i
    ) external view returns (TraitData memory);

    function getChoosenHistoryIndex(uint256 i) external view returns (uint256);

    function isUninitialized(uint256 nftId) external view returns (bool);
}
