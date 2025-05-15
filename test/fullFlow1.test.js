const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("💼 Simulate full NFT issuance + multi-investor purchase + revenue with tax", function () {
  let contract, idrt, owner, fundManager, taxAccount;
  let investorA, investorB, investorC;
  const TAX_RATE = 5; // 5%

  beforeEach(async () => {
    [owner, fundManager, taxAccount, investorA, investorB, investorC] = await ethers.getSigners();

    const MockIDRT = await ethers.getContractFactory("MockIDRT");
    idrt = await MockIDRT.deploy();
    await idrt.deployed();

    const DirectionNFT = await ethers.getContractFactory("DirectionNFT");
    contract = await upgrades.deployProxy(DirectionNFT, [
      "https://example.com/", idrt.address
    ], { initializer: "initializeAll" });
    await contract.deployed();

    await contract.grantRole(await contract.FUND_MANAGER_ROLE(), fundManager.address);
    await contract.grantRole(await contract.ESCROW_ROLE(), owner.address);
    await contract.grantRole(await contract.ESCROW_ROLE(), taxAccount.address);
  });

  it("🌐 NFT issuance → multi-investor buy → revenue distribution with tax", async () => {
    // NFT issuance
    const metadataUri = "https://nft.land/property-xyz-" + Date.now();
    const docHash = ethers.utils.formatBytes32String("meta-doc-" + Date.now());
    const totalUnits = 10;

    console.log("🏗️  Creating NFT:", metadataUri);
    await contract.connect(fundManager).mintToken(owner.address, totalUnits, metadataUri, docHash);
    const tokenId = await contract.tokenIdCounter();

    await contract.connect(owner).setApprovalForAll(contract.address, true);
    await contract.connect(owner).createListing(tokenId, ethers.utils.parseEther("10"), totalUnits);

    // Prepare investors
    const investors = [investorA, investorB, investorC];
    const portions = [4, 3, 3]; // Total = 10 units (100%)
    const pricePerUnit = ethers.utils.parseEther("10");

    for (let i = 0; i < investors.length; i++) {
      const totalCost = pricePerUnit.mul(portions[i]);
      await idrt.faucet(investors[i].address, totalCost);
      await idrt.connect(investors[i]).approve(contract.address, totalCost);
    }

    // Investors buy
    for (let i = 0; i < investors.length; i++) {
      const listingId = await contract.listingCounter();
      await contract.connect(investors[i]).executePurchase(listingId);
      console.log(`✅ Investor ${i + 1} (${investors[i].address}) bought ${portions[i]} units`);
    }

    // Revenue injection
    const grossRevenue = ethers.utils.parseEther("100");
    const taxAmount = grossRevenue.mul(TAX_RATE).div(100);
    const netRevenue = grossRevenue.sub(taxAmount);

    await idrt.faucet(owner.address, grossRevenue);
    await idrt.connect(owner).transfer(contract.address, grossRevenue);

    // Flag and release tax
    await contract.connect(owner).flagTax(taxAccount.address, "5%", taxAmount);
    await contract.connect(owner).releaseFunds(taxAccount.address, taxAmount);

    // Revenue distribution
    await contract.connect(owner).distributeRevenue(tokenId, netRevenue);

    console.log("💸 Gross Revenue:", ethers.utils.formatEther(grossRevenue));
    console.log("🏛️  Tax (5%) sent to:", taxAccount.address, "=", ethers.utils.formatEther(taxAmount));
    console.log("📤 Net Revenue distributed:", ethers.utils.formatEther(netRevenue));

    // Each investor claims
    for (let i = 0; i < investors.length; i++) {
      const before = await idrt.balanceOf(investors[i].address);
      await contract.claimRevenue(investors[i].address, tokenId);
      const after = await idrt.balanceOf(investors[i].address);
      const expected = netRevenue.mul(portions[i]).div(totalUnits);
      const received = after.sub(before);
      console.log(`📥 Investor ${i + 1} received: ${ethers.utils.formatEther(received)} IDRT (Expected: ${ethers.utils.formatEther(expected)})`);
      expect(received).to.eq(expected);
    }
  });
}); 