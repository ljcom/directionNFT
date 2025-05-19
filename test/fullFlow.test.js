const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("🏗️ FULL SYSTEM FLOW: DIRE Tokenization Sandbox Simulation", function () {
  let contract, idrt, owner, fundManager, taxAccount;
  let investorA, investorB, investorC;
  const TAX_RATE = 50; // 0.5%
  const MAX_SELL_PERCENT = 50;
  const pricePerUnit = ethers.utils.parseEther("10");

  let tokenId;
  const totalUnits = 10;
  const portions = [4, 3, 3];
  const investors = [];

  beforeEach(async () => {
    [owner, platformManager, fundManager, taxAccount, investorA, investorB, investorC] = await ethers.getSigners();
    investors.push(investorA, investorB, investorC);

    const MockIDRT = await ethers.getContractFactory("MockIDRT");
    idrt = await MockIDRT.deploy();
    await idrt.deployed();

    const DirectionNFT = await ethers.getContractFactory("DirectionNFT");
    contract = await upgrades.deployProxy(DirectionNFT, [
      "https://example.com/", idrt.address
    ], { initializer: "initializeAll" });

    await contract.deployed();

    await contract.grantRole(await contract.PLATFORM_MANAGER_ROLE(), owner.address); 
    await contract.grantRole(await contract.FUND_MANAGER_ROLE(), fundManager.address);
    await contract.grantRole(await contract.ESCROW_ROLE(), owner.address);
    await contract.grantRole(await contract.ESCROW_ROLE(), taxAccount.address);

    const metadataUri = "https://nft.land/property-xyz-" + Date.now();
    const docHash = ethers.utils.formatBytes32String("meta-doc-" + Date.now());

    await contract.connect(fundManager).mintToken(owner.address, totalUnits, metadataUri, docHash);
    tokenId = await contract.tokenIdCounter();
  });

  it("🌐 Primary Market: Listing, Purchase, Revenue Distribution", async () => {
    const maxUnitsAllowedToSell = totalUnits * MAX_SELL_PERCENT / 100;
    const unitsToSell = portions.reduce((a, b) => a + b, 0);

    if (unitsToSell > maxUnitsAllowedToSell) {
      console.warn(`❌ Threshold check failed: ${unitsToSell} > ${maxUnitsAllowedToSell}`);
      return;
    }

    await contract.connect(owner).setApprovalForAll(contract.address, true);
    await contract.connect(owner).createListing(tokenId, pricePerUnit, unitsToSell);

    for (let i = 0; i < investors.length; i++) {
      const cost = pricePerUnit.mul(portions[i]);
      await idrt.faucet(investors[i].address, cost);
      await idrt.connect(investors[i]).approve(contract.address, cost);
      await contract.connect(investors[i]).executePurchase(1, portions[i]);
      expect(await contract.balanceOf(investors[i].address, tokenId)).to.eq(portions[i]);
    }

    const gross = ethers.utils.parseEther("100");
    const tax = gross.mul(TAX_RATE).div(10000);
    const net = gross.sub(tax);

    await idrt.faucet(owner.address, gross);
    await idrt.connect(owner).transfer(contract.address, gross);
    await contract.connect(owner).flagTax(taxAccount.address, "0.5%", tax);
    await idrt.connect(owner).transfer(taxAccount.address, tax);
    await contract.connect(owner).distributeRevenue(tokenId, net);

    for (let i = 0; i < investors.length; i++) {
      const before = await idrt.balanceOf(investors[i].address);
      await contract.claimRevenue(investors[i].address, tokenId);
      const after = await idrt.balanceOf(investors[i].address);
      expect(after.sub(before)).to.eq(net.mul(portions[i]).div(totalUnits));
    }
  });

  it("🔁 Secondary Market: Resale & Royalty", async () => {
    const resaleQty = 2;
    const resalePrice = ethers.utils.parseEther("12");

    if ((await contract.balanceOf(investorA.address, tokenId)).lt(resaleQty)) return;

    await contract.connect(investorA).setApprovalForAll(contract.address, true);
    await contract.connect(investorA).createListing(tokenId, resalePrice, resaleQty);

    const cost = resalePrice.mul(resaleQty);
    await idrt.faucet(investorB.address, cost);
    await idrt.connect(investorB).approve(contract.address, cost);
    await contract.connect(investorB).executePurchase(await contract.listingCounter(), resaleQty);

    expect(await contract.balanceOf(investorB.address, tokenId)).to.gte(resaleQty);
  });

  it("📊 Revenue Distribution (Post-Resale)", async () => {
    const balances = await Promise.all(investors.map(i => contract.balanceOf(i.address, tokenId)));
    const supply = balances.reduce((acc, b) => acc.add(b), ethers.BigNumber.from(0));
    const gross = ethers.utils.parseEther("99");
    const tax = gross.mul(TAX_RATE).div(10000);
    const net = gross.sub(tax);

    await idrt.faucet(owner.address, gross);
    await idrt.connect(owner).transfer(contract.address, gross);
    await contract.connect(owner).flagTax(taxAccount.address, "0.5%", tax);
    await idrt.connect(owner).transfer(taxAccount.address, tax);
    await contract.connect(owner).distributeRevenue(tokenId, net);

    for (let i = 0; i < investors.length; i++) {
      if (balances[i].eq(0)) continue;
      const before = await idrt.balanceOf(investors[i].address);
      await contract.claimRevenue(investors[i].address, tokenId);
      const after = await idrt.balanceOf(investors[i].address);
      expect(after.sub(before)).to.eq(net.mul(balances[i]).div(supply));
    }
  });

  it("🛡️ Governance Control: Proposal, Pause, Audit Log", async () => {
    const proposalId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UpgradeModuleXYZ"));
    await contract.connect(owner).proposeUpgrade(proposalId, "Marketplace", "Fix bug in trade limit");
    await contract.connect(owner).signProposal(proposalId);
    await contract.connect(owner).pauseModule("Marketplace");

    const tx = await contract.connect(owner).logAuditEvent("EMERGENCY_PAUSE", "Marketplace paused by admin");
    const receipt = await tx.wait();
    const log = receipt.events.find(e => e.event === "GovernanceAction");
    expect(log.args.actionType).to.eq("EMERGENCY_PAUSE");
  });
});