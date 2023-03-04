import { ethers } from "hardhat";
import { deployOrLoadAndVerify, getOutputAddress } from "../utils";

async function main() {
  const maha = await getOutputAddress("MAHA");
  const locker = await getOutputAddress("MAHAXLocker");
  const weth = await getOutputAddress("WETH");
  const metadataManager = await getOutputAddress("MetadataManager");
  const governance = "0x547283f06b4479fa8bf641caa2ddc7276d4899bf";

  const deploy = await deployOrLoadAndVerify(
    "ETHMahaXLockerV2",
    "ETHMahaXLocker",
    []
  );

  const instance = await ethers.getContractAt("ETHMahaXLocker", deploy.address);

  console.log("initalize");
  await instance.initialize(
    locker, // address _locker,
    maha, // address _maha,
    weth, // address _weth,
    "0xE592427A0AEce92De3Edee1F18E0157C05861564", // address _router,
    metadataManager // address _metadataManager
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
