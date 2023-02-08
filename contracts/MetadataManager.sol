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
    mapping(uint256 => TraitData) public traitdata;
    mapping(uint256 => LockData) public lockData;

    function initialize(
        address _locker,
        address _governance
    ) external initializer {
        locker = INFTLocker(_locker);
        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    }

    function setTrait(
        uint256 nftId,
        TraitData memory data
    ) external onlyRole(TRAIT_SETTER_ROLE) {
        traitdata[nftId] = data;

        // TODO: capture MAHAX history from locker contract and record

        emit TraitDataSet(msg.sender, nftId, data);
    }

    function evolve(
        uint256 nftId,
        TraitData memory data
    ) external onlyRole(TRAIT_SETTER_ROLE) {
        traitdata[nftId] = data;
        emit TraitDataSet(msg.sender, nftId, data);
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

    function _canEvolve(
        uint256 prevMAHAX,
        uint256 currentMAHAX
    ) internal pure returns (bool) {
        return prevMAHAX + 100e18 < currentMAHAX;
    }
}
