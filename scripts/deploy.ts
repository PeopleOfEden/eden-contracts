import { deployOrLoadAndVerify } from "./utils";

async function main() {
  const maha = "0x90344dD6Dc73A6FDa00A9e8315065662cFf43228";
  const locker = "0x9ee8110c0aACb7f9147252d7A2D95a5ff52F8496";
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
