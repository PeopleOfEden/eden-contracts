import { ethers } from "hardhat";
import { deployOrLoadAndVerify, getOutputAddress } from "../utils";

async function main() {
  const maha = await getOutputAddress("MAHA");
  const locker = await getOutputAddress("MAHAXLocker");
  const governance = "0x77cd66d59ac48a0E7CE54fF16D9235a5fffF335E";
  const gaugeProxyAdmin = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const implementation = await deployOrLoadAndVerify(
    `MetadataManagerImpl`,
    "MetadataManager",
    []
  );

  const MetadataManager = await ethers.getContractFactory("MetadataManager");
  const initData = MetadataManager.interface.encodeFunctionData("initialize", [
    maha,
    locker,
    governance,
  ]);

  await deployOrLoadAndVerify(
    "MetadataManager",
    "TransparentUpgradeableProxy",
    [implementation.address, gaugeProxyAdmin, initData]
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
