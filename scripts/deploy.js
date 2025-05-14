const { ethers, upgrades } = require("hardhat");

async function main() {
  const DirectionNFT = await ethers.getContractFactory("DirectionNFT");
  const proxy = await upgrades.deployProxy(DirectionNFT, ["https://your-base-uri.com/"], {
    initializer: "initializeAll"
  });

  await proxy.deployed();
  console.log(`✅ Proxy deployed to: ${proxy.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});