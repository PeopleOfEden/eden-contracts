// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {IMetadataManager} from "./interfaces/IMetadataManager.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {VersionedInitializable} from "./proxy/VersionedInitializable.sol";
import {INFTLocker} from "./interfaces/INFTLocker.sol";

contract Metadata is
    IMetadataManager,
    AccessControlEnumerable,
    VersionedInitializable
{
    bytes32 public TRAIT_SETTER_ROLE = keccak256("TRAIT_SETTER_ROLE");

    INFTLocker public locker;

    // a history of all the traits
    mapping(uint256 => mapping(uint256 => TraitData)) public dataHistory;

    // nft id -> how much trait data has been recorded
    mapping(uint256 => uint256) public historyCount;

    function initialize(
        address _locker,
        address _governance
    ) external initializer {
        locker = INFTLocker(_locker);
        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    }

    function initTraits(uint256 nftId, TraitData memory data) external {
        require(historyCount[nftId] == 0, "traits already set");
        require(locker.ownerOf(nftId) == msg.sender, "only nft owner");
        _addData(nftId, data);
    }

    function setTrait(
        uint256 nftId,
        TraitData memory data
    ) external onlyRole(TRAIT_SETTER_ROLE) {
        _addData(nftId, data);
    }

    function evolve(uint256 nftId) external onlyRole(TRAIT_SETTER_ROLE) {
        TraitData memory old = _getLatestTraitData(nftId);

        // check if the nft can evovle based on the previously recorded MAHAX value
        uint256 oldMAHAX = old.lastRecordedMAHAX;
        uint256 newMAHAX = getMAHAXWithouDecay(nftId);
        require(_canEvolve(oldMAHAX, newMAHAX), "cant evolve");

        // if all good, then record the new values
        _addData(nftId, old);
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 0;
    }

    function canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) external pure override returns (bool) {
        return _canEvolve(prevMAHAX, currentMAHAX);
    }

    function getLatestTraitData(
        uint256 nftId
    ) external view returns (TraitData memory data) {
        return _getLatestTraitData(nftId);
    }

    function _canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) internal pure returns (bool) {
        if (prevMAHAX > currentMAHAX) return false;

        // follow a curve; a person can evolve a NFT 13 times.
        if (prevMAHAX <= 100 && currentMAHAX >= 150) return true;
        if (prevMAHAX <= 150 && currentMAHAX >= 250) return true;
        if (prevMAHAX <= 250 && currentMAHAX >= 400) return true;
        if (prevMAHAX <= 400 && currentMAHAX >= 600) return true;
        if (prevMAHAX <= 600 && currentMAHAX >= 1000) return true;
        if (prevMAHAX <= 1000 && currentMAHAX >= 2000) return true;
        if (prevMAHAX <= 2000 && currentMAHAX >= 3000) return true;
        if (prevMAHAX <= 3000 && currentMAHAX >= 4000) return true;
        if (prevMAHAX <= 4000 && currentMAHAX >= 5000) return true;
        if (prevMAHAX <= 5000 && currentMAHAX >= 7500) return true;
        if (prevMAHAX <= 7500 && currentMAHAX >= 10000) return true;
        if (prevMAHAX <= 10000 && currentMAHAX >= 12000) return true;
        if (prevMAHAX <= 15000 && currentMAHAX >= 20000) return true;

        // beyond 25k MAHAX, the NFT is maxed out... no more evolutions
        if (prevMAHAX <= 20000 && currentMAHAX >= 25000) return true;

        return false;
    }

    function _addData(uint256 nftId, TraitData memory data) internal {
        data.lastRecordedMAHAX = getMAHAXWithouDecay(nftId);
        data.lastRecordedAt = block.timestamp;

        // record into mapping
        dataHistory[nftId][historyCount[nftId]] = data;

        // increment history counter
        historyCount[nftId] += 1;

        // emit event
        emit TraitDataSet(msg.sender, nftId, data);
    }

    function _getLatestTraitData(
        uint256 nftId
    ) internal view returns (TraitData memory data) {
        return dataHistory[nftId][historyCount[nftId] - 1];
    }

    function getMAHAXWithouDecay(
        uint256 nftId
    ) public view returns (uint256 mahax) {
        INFTLocker.LockedBalance memory lock = locker.locked(nftId);
        return
            (uint128(lock.amount) * (lock.end - lock.start)) /
            (4 * 365 * 86400);
    }
}
