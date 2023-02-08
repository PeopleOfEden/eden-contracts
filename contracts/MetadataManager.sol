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
        return prevMAHAX + 100e18 < currentMAHAX;
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
