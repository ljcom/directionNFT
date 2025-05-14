const { ethers, upgrades } = require("hardhat");

async function main() {
  const newImpl = await ethers.getContractFactory("DirectionNFT");
  const proxyAddress = "PASTE_PROXY_ADDRESS_HERE";

  const upgraded = await upgrades.upgradeProxy(proxyAddress, newImpl);
  console.log(`✅ Contract upgraded at: ${upgraded.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});