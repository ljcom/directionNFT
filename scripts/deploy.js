// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy MockIDRT (ERC20)
  const MockIDRT = await ethers.getContractFactory("MockIDRT");
  const idrt = await MockIDRT.deploy();
  await idrt.deployed();
  console.log("✅ MockIDRT deployed to:", idrt.address);

  // 2. Deploy DirectionNFT (proxy)
  const DirectionNFT = await ethers.getContractFactory("DirectionNFT");
  const directionNFT = await upgrades.deployProxy(
    DirectionNFT,
    ["https://example.com/", idrt.address],
    { initializer: "initializeAll" }
  );
  await directionNFT.deployed();
  console.log("✅ DirectionNFT proxy deployed to:", directionNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });