const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying MockIDRT from:", deployer.address);

  const MockIDRT = await ethers.getContractFactory("MockIDRT");
  const token = await MockIDRT.deploy();

  await token.deployed();

  console.log("MockIDRT deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});