// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {IMetadataManager} from "./interfaces/IMetadataManager.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {VersionedInitializable} from "./proxy/VersionedInitializable.sol";
import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {ITokenURIGenerator} from "./interfaces/ITokenURIGenerator.sol";

contract MetadataManager is
    ITokenURIGenerator,
    IMetadataManager,
    AccessControlEnumerable,
    VersionedInitializable
{
    bytes32 public TRAIT_SETTER_ROLE;

    INFTLocker public locker;

    /// @dev a history of all the traits
    mapping(uint256 => mapping(uint256 => TraitData)) public traitHistory;

    /// @dev nft id -> how much trait data has been recorded
    mapping(uint256 => uint256) public historyCount;

    /// @dev nft id -> a history override
    mapping(uint256 => uint256) public historyOverride;

    function initialize(
        address _locker,
        address _governance
    ) external initializer {
        locker = INFTLocker(_locker);
        TRAIT_SETTER_ROLE = keccak256("TRAIT_SETTER_ROLE");
        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    }

    /// @notice anyone can initialize their traits if it hasn't been set already.
    function initTraits(uint256 nftId, TraitData memory data) external {
        require(historyCount[nftId] == 0, "traits already set");
        require(locker.ownerOf(nftId) == msg.sender, "only nft owner");
        _addData(nftId, data);
    }

    /// @notice special trusted contracts can update traits on behalf of a NFT
    function setTrait(
        uint256 nftId,
        TraitData memory data
    ) external onlyRole(TRAIT_SETTER_ROLE) {
        _addData(nftId, data);
    }

    /// @notice evolve the traits of a NFT. callable only by the nft owner
    function evolve(uint256 nftId) external {
        require(locker.ownerOf(nftId) == msg.sender, "only nft owner");

        TraitData memory old = _getLatestTraitData(nftId);

        // check if the nft can evovle based on the previously recorded MAHAX value
        uint256 oldMAHAX = old.lastRecordedMAHAX;
        uint256 newMAHAX = getMAHAXWithouDecay(nftId);
        require(_canEvolve(oldMAHAX, newMAHAX), "cant evolve");

        // reset the history
        if (historyOverride[nftId] > 0) historyOverride[nftId] = 0;

        // if all good, then record the new values
        _addData(nftId, old);
        emit NFTEvolved(msg.sender, nftId, oldMAHAX, newMAHAX);
    }

    function overrideHistory(uint256 nftId, uint256 index) external {
        require(locker.ownerOf(nftId) == msg.sender, "only nft owner");
        require(index <= historyCount[nftId], "index < count");
        require(index > 0, "index > 0");

        historyOverride[nftId] = index;
        emit NFTHistoryOverrided(msg.sender, nftId, index);
    }

    /// @notice can a NFT evovle?
    function canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) external pure override returns (bool) {
        return _canEvolve(prevMAHAX, currentMAHAX);
    }

    function canNFTEvolve(uint256 nftId) external view override returns (bool) {
        TraitData memory old = _getLatestTraitData(nftId);
        uint256 oldMAHAX = old.lastRecordedMAHAX;
        uint256 newMAHAX = getMAHAXWithouDecay(nftId);
        return _canEvolve(oldMAHAX, newMAHAX);
    }

    function getLatestTraitData(
        uint256 nftId
    ) external view override returns (TraitData memory) {
        return _getLatestTraitData(nftId);
    }

    function getChoosenHistoryIndex(
        uint256 nftId
    ) external view override returns (uint256) {
        return _getChoosenHistoryIndex(nftId);
    }

    function isUninitialized(
        uint256 nftId
    ) external view override returns (bool) {
        return historyCount[nftId] == 0;
    }

    function _canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) internal pure returns (bool) {
        if (prevMAHAX > currentMAHAX) return false;

        // follow a curve; a person can evolve a NFT 13 times.
        if (prevMAHAX <= 100e18 && currentMAHAX >= 150e18) return true;
        if (prevMAHAX <= 150e18 && currentMAHAX >= 250e18) return true;
        if (prevMAHAX <= 250e18 && currentMAHAX >= 400e18) return true;
        if (prevMAHAX <= 400e18 && currentMAHAX >= 600e18) return true;
        if (prevMAHAX <= 600e18 && currentMAHAX >= 1000e18) return true;
        if (prevMAHAX <= 1000e18 && currentMAHAX >= 2000e18) return true;
        if (prevMAHAX <= 2000e18 && currentMAHAX >= 3000e18) return true;
        if (prevMAHAX <= 3000e18 && currentMAHAX >= 4000e18) return true;
        if (prevMAHAX <= 4000e18 && currentMAHAX >= 5000e18) return true;
        if (prevMAHAX <= 5000e18 && currentMAHAX >= 7500e18) return true;
        if (prevMAHAX <= 7500e18 && currentMAHAX >= 10000e18) return true;
        if (prevMAHAX <= 10000e18 && currentMAHAX >= 12000e18) return true;
        if (prevMAHAX <= 15000e18 && currentMAHAX >= 20000e18) return true;

        // beyond 25k MAHAX, the NFT is maxed out... no more evolutions
        if (prevMAHAX <= 20000e18 && currentMAHAX >= 25000e18) return true;

        return false;
    }

    /// @dev Returns current token URI metadata
    /// @param _tokenId Token ID to fetch URI for.
    function tokenURI(
        uint256 _tokenId
    ) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://staging-api.peopleofeden.com/token-uri/id-",
                    _toString(_tokenId),
                    "-history-",
                    _toString(_getChoosenHistoryIndex(_tokenId)),
                    ".json"
                )
            );
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _addData(uint256 nftId, TraitData memory data) internal {
        data.lastRecordedMAHAX = getMAHAXWithouDecay(nftId);
        data.lastRecordedAt = block.timestamp;

        require(_validateTraitData(data), "invalid trait data");

        // record into mapping
        traitHistory[nftId][historyCount[nftId]] = data;

        // increment history counter
        historyCount[nftId] += 1;

        // emit event
        emit TraitDataSet(msg.sender, nftId, data);
    }

    function _getLatestTraitData(
        uint256 nftId
    ) internal view returns (TraitData memory data) {
        if (historyCount[nftId] == 0)
            return
                TraitData({
                    gender: 0,
                    skin: 0,
                    dnaMetadata: 0,
                    lastRecordedMAHAX: 0,
                    lastRecordedAt: 0
                });

        return traitHistory[nftId][historyCount[nftId] - 1];
    }

    function _getChoosenHistoryIndex(
        uint256 nftId
    ) internal view returns (uint256) {
        if (historyOverride[nftId] > 0) return historyOverride[nftId];
        if (historyCount[nftId] > 0) return historyCount[nftId];
        return 0;
    }

    function _getChoosenTraitData(
        uint256 nftId
    ) internal view returns (TraitData memory data) {
        return traitHistory[nftId][_getChoosenHistoryIndex(nftId) - 1];
    }

    function _validateTraitData(
        TraitData memory d
    ) internal view returns (bool) {
        return
            d.gender > 0 &&
            d.skin > 0 &&
            d.lastRecordedMAHAX > 0 &&
            d.lastRecordedAt >= block.timestamp;
    }

    function getMAHAXWithouDecay(
        uint256 nftId
    ) public view returns (uint256 mahax) {
        INFTLocker.LockedBalance memory lock = locker.locked(nftId);
        return
            (uint128(lock.amount) * (lock.end - lock.start)) /
            (4 * 365 * 86400);
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 0;
    }
}
