import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MetadataManager, MockERC20, TestLocker } from "../typechain-types";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe.skip("ETHMahaXLocker", function () {
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

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const maha: MockERC20 = await MockERC20.deploy("MAHA", "MAHA", 18);

    await manager.initialize(maha.address, locker.address, owner.address);

    return { locker, maha, manager, owner, otherAccount };
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
  });

  describe("init from referral tests", function () {
    // test
  });
});
