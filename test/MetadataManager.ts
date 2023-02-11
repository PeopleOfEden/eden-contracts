import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MetadataManager, TestLocker } from "../typechain-types";
import { BigNumber } from "ethers";

describe("MetadataManager", function () {
  const e18 = BigNumber.from(10).pow(18);

  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestLocker = await ethers.getContractFactory("TestLocker");
    const locker: TestLocker = await TestLocker.deploy();

    const MetadataManager = await ethers.getContractFactory("MetadataManager");
    const manager: MetadataManager = await MetadataManager.deploy();

    await manager.initialize(locker.address, owner.address);

    return { locker, manager, owner, otherAccount };
  }

  interface ITraitData {
    gender: number;
    skin: number;
    dnaMetadata: BigNumber;
    lastRecordedMAHAX: BigNumber;
    lastRecordedAt: BigNumber;
  }

  const traitDataEq = (a: ITraitData, b: ITraitData) =>
    a.gender === b.gender &&
    a.skin === b.skin &&
    a.dnaMetadata.eq(b.dnaMetadata) &&
    a.lastRecordedMAHAX.eq(b.lastRecordedMAHAX) &&
    a.lastRecordedAt.eq(b.lastRecordedAt);

  const blankTrait = {
    gender: 0,
    skin: 0,
    dnaMetadata: BigNumber.from("0"),
    lastRecordedMAHAX: BigNumber.from("0"),
    lastRecordedAt: BigNumber.from("0"),
  };

  describe("should deploy properly", function () {
    it("should report right mahax. id = 1 -> 250 MAHAX", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.getMAHAXWithouDecay(1)).to.equal(e18.mul(250));
    });

    it("should report right mahax. id = 2 -> 0 MAHAX", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.getMAHAXWithouDecay(2)).to.equal(0);
    });

    it("should allow evolve. id = 1", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.canNFTEvolve(1)).to.equal(true);
    });

    it("should disallow evolve. id = 2", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.canNFTEvolve(2)).to.equal(false);
    });

    it("should get blank traits for id = 1", async function () {
      const { manager } = await loadFixture(deployFixture);
      const recvdData = await manager.getLatestTraitData(1);
      expect(traitDataEq(recvdData, blankTrait)).to.equal(true);
    });

    it("should get blank traits for id = 2", async function () {
      const { manager } = await loadFixture(deployFixture);
      const recvdData = await manager.getLatestTraitData(2);
      expect(traitDataEq(recvdData, blankTrait)).to.equal(true);
    });

    it("should get uninitialized for id = 1", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.isUninitialized(1)).to.equal(true);
    });
  });

  describe("init from referral tests", function () {
    // test
  });

  describe.only("init from msg.sender tests", function () {
    let _manager: MetadataManager;

    beforeEach("have a init contract ", async function () {
      const { manager, owner } = await loadFixture(deployFixture);

      const d: ITraitData = {
        gender: 0,
        skin: 0,
        dnaMetadata: BigNumber.from(0),
        lastRecordedMAHAX: BigNumber.from(0),
        lastRecordedAt: BigNumber.from(0),
      };

      await manager.connect(owner).initTraits(1, d);

      _manager = manager;
    });

    it("should get initialized for id = 1", async function () {
      expect(await _manager.isUninitialized(1)).to.equal(false);
    });
  });

  describe("evolution tests", function () {
    // test
  });

  describe("history tests", function () {
    // test
  });

  describe("history override tests", function () {
    // test
  });
});
