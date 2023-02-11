import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MetadataManager, TestLocker } from "../typechain-types";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

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

    it("should report no history count for id = 1", async function () {
      const { manager } = await loadFixture(deployFixture);
      expect(await manager.historyCount(1)).to.equal(0);
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

    it("should report right token uri for id = 1", async function () {
      const { manager } = await loadFixture(deployFixture);
      const d = await manager.tokenURI(1);
      expect(d.endsWith("/token-uri/id-1-history-0.json")).to.equal(true);
    });
  });

  describe("init from referral tests", function () {
    // test
  });

  describe("init from msg.sender tests", function () {
    let _manager: MetadataManager;

    beforeEach("init the traits once ", async function () {
      const { manager, owner } = await loadFixture(deployFixture);

      const d: ITraitData = {
        gender: 1,
        skin: 1,
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

    it("should report right metadata for id = 1", async function () {
      const d = await _manager.getLatestTraitData(1);
      expect(d.gender).to.equal(1);
      expect(d.skin).to.equal(1);
      expect(d.dnaMetadata).to.equal(0);
      expect(d.lastRecordedMAHAX).to.equal(e18.mul(250));
      expect(d.lastRecordedAt).to.be.greaterThan(0);
    });

    it("should report no history count for id = 1", async function () {
      const d = await _manager.historyCount(1);
      expect(d).to.equal(1);
    });

    it("should report no history overrides for id = 1", async function () {
      const d = await _manager.historyOverride(1);
      expect(d).to.equal(0);
    });

    it("should report right token uri for id = 1", async function () {
      const d = await _manager.tokenURI(1);
      expect(d.endsWith("/token-uri/id-1-history-1.json")).to.equal(true);
    });
  });

  describe("evolution tests", function () {
    let _manager: MetadataManager;
    let _locker: TestLocker;
    let _owner: SignerWithAddress;

    describe("when maha locked is less", async function () {
      this.beforeEach("lock 100 maha", async function () {
        const { manager, owner, locker } = await loadFixture(deployFixture);

        const d: ITraitData = {
          gender: 1,
          skin: 1,
          dnaMetadata: BigNumber.from(0),
          lastRecordedMAHAX: BigNumber.from(0),
          lastRecordedAt: BigNumber.from(0),
        };

        await manager.connect(owner).initTraits(1, d);
        _manager = manager;

        // increase lock amount by 100 maha
        await locker.increaseLockAmount(e18.mul(100));
        _locker = locker;
      });

      it("should update lock details", async function () {
        const lock = await _locker.locked(1);
        expect(lock.amount).to.equal(e18.mul(1100));
      });

      it("should not allow to evolve", async function () {
        expect(await _manager.canNFTEvolve(1)).to.equal(false);
      });

      it("should allow to evolve after locking more", async function () {
        await _locker.increaseLockAmount(e18.mul(1000));
        expect(await _manager.canNFTEvolve(1)).to.equal(true);
      });
    });

    describe("when maha locked is enough", async function () {
      this.beforeEach("lock 400 maha", async function () {
        const { manager, owner, locker } = await loadFixture(deployFixture);

        const d: ITraitData = {
          gender: 1,
          skin: 1,
          dnaMetadata: BigNumber.from(0),
          lastRecordedMAHAX: BigNumber.from(0),
          lastRecordedAt: BigNumber.from(0),
        };

        await manager.connect(owner).initTraits(1, d);
        _manager = manager;

        // increase lock amount by 1000 mahax
        await locker.increaseLockAmount(e18.mul(400));
        _locker = locker;
        _owner = owner;
      });

      it("should allow to evolve", async function () {
        expect(await _manager.canNFTEvolve(1)).to.equal(true);
      });

      describe("perform a evolve", async function () {
        this.beforeEach("evolve the nft", async function () {
          await _manager.connect(_owner).evolve(1);
        });

        it("should now allow any more evolutions", async function () {
          expect(await _manager.canNFTEvolve(1)).to.equal(false);
        });

        it("should add new trait data to the history", async function () {
          expect(await _manager.historyCount(1)).to.equal(2);
        });

        it("should report a new token uri", async function () {
          const d = await _manager.tokenURI(1);
          expect(d.endsWith("/token-uri/id-1-history-2.json")).to.equal(true);
        });
      });
    });
  });

  describe("history override tests", function () {
    let _manager: MetadataManager;
    let _locker: TestLocker;
    let _owner: SignerWithAddress;

    describe("when maha is locked and we evolve once", async function () {
      this.beforeEach("lock 1000 maha and evolve", async function () {
        const { manager, owner, locker } = await loadFixture(deployFixture);
        _manager = manager;
        _locker = locker;
        _owner = owner;

        const d: ITraitData = {
          gender: 1,
          skin: 1,
          dnaMetadata: BigNumber.from(0),
          lastRecordedMAHAX: BigNumber.from(0),
          lastRecordedAt: BigNumber.from(0),
        };

        await manager.connect(owner).initTraits(1, d);
        await locker.increaseLockAmount(e18.mul(1000));
        await manager.connect(owner).evolve(1);

        // override history
        await manager.overrideHistory(1, 1);
      });

      it("should set override history", async function () {
        expect(await _manager.historyOverride(1)).to.equal(1);
      });

      it("should return old token uri", async function () {
        const d = await _manager.tokenURI(1);
        expect(d.endsWith("/token-uri/id-1-history-1.json")).to.equal(true);
      });

      it("should report right history count for id = 1", async function () {
        expect(await _manager.historyCount(1)).to.equal(2);
      });
    });
  });
});
