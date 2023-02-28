import { deployOrLoadAndVerify, getOutputAddress } from "../utils";

async function main() {
  const maha = await getOutputAddress("MAHA");
  const locker = await getOutputAddress("MAHAXLocker");
  const governance = "0x547283f06b4479fa8bf641caa2ddc7276d4899bf";

  const manager = await deployOrLoadAndVerify(
    "MetadataManager",
    "MetadataManager",
    []
  );

  await manager.initialize(maha, locker, governance);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
