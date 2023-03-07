import { ethers } from "hardhat";
import { deployOrLoadAndVerify, getOutputAddress } from "../utils";

async function main() {
  const maha = await getOutputAddress("MAHA");
  const locker = await getOutputAddress("MAHAXLocker");
  const weth = await getOutputAddress("WETH");
  const metadataManager = await getOutputAddress("MetadataManager");
  const gaugeProxyAdmin = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const implementation = await deployOrLoadAndVerify(
    `ETHMahaXLockerImpl`,
    "ETHMahaXLocker",
    []
  );

  const ETHMahaXLocker = await ethers.getContractFactory("ETHMahaXLocker");
  const initData = ETHMahaXLocker.interface.encodeFunctionData("initialize", [
    locker, // address _locker,
    maha, // address _maha,
    weth, // address _weth,
    "0xE592427A0AEce92De3Edee1F18E0157C05861564", // address _router,
    metadataManager, // address _metadataManager
  ]);

  await deployOrLoadAndVerify("ETHMahaXLocker", "TransparentUpgradeableProxy", [
    implementation.address,
    gaugeProxyAdmin,
    initData,
  ]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
