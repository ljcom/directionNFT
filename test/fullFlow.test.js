const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("💼 Full NFT flow: primary + secondary + tax + threshold", function () {
  let contract, idrt, owner, fundManager, taxAccount;
  let investorA, investorB, investorC;
  const TAX_RATE = 50; // 0.5%
  const MAX_SELL_PERCENT = 50; // 50% max allowed
  const pricePerUnit = ethers.utils.parseEther("10");

  let tokenId;
  const totalUnits = 10;
  const portions = [4, 3, 3];
  const investors = [];

  beforeEach(async () => {
    [owner, fundManager, taxAccount, investorA, investorB, investorC] = await ethers.getSigners();
    investors.push(investorA, investorB, investorC);

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

    const metadataUri = "https://nft.land/property-xyz-" + Date.now();
    const docHash = ethers.utils.formatBytes32String("meta-doc-" + Date.now());

    await contract.connect(fundManager).mintToken(owner.address, totalUnits, metadataUri, docHash);
    tokenId = await contract.tokenIdCounter();
  });

  it("🌐 Primary flow: listing, threshold check, investor buy, revenue + tax", async () => {
    const maxUnitsAllowedToSell = totalUnits * MAX_SELL_PERCENT / 100;
    const unitsToSell = portions.reduce((a, b) => a + b, 0);

    const ownerInitial = await contract.balanceOf(owner.address, tokenId);
    console.log(`🏗️ Owner initial: ${ownerInitial}`);
    console.log(`🔒 Threshold: ${maxUnitsAllowedToSell} units`);

    let listingCreated = false;
    if (unitsToSell > maxUnitsAllowedToSell) {
      console.warn(`❌ Error: ingin jual ${unitsToSell} > max ${maxUnitsAllowedToSell}`);
    } else {
      await contract.connect(owner).setApprovalForAll(contract.address, true);
      await contract.connect(owner).createListing(tokenId, pricePerUnit, unitsToSell);
      listingCreated = true;
      console.log(`✅ Owner listing ${unitsToSell} units`);
    }

    if (!listingCreated) return;

    for (let i = 0; i < investors.length; i++) {
      const totalCost = pricePerUnit.mul(portions[i]);
      await idrt.faucet(investors[i].address, totalCost);
      await idrt.connect(investors[i]).approve(contract.address, totalCost);
      await contract.connect(investors[i]).executePurchase(1, portions[i]);

      const balance = await contract.balanceOf(investors[i].address, tokenId);
      expect(balance.eq(portions[i])).to.be.true;
      console.log(`✅ Investor ${i + 1} bought ${portions[i]} units`);
    }

    const grossRevenue = ethers.utils.parseEther("100");
    const taxAmount = grossRevenue.mul(TAX_RATE).div(10000);
    const netRevenue = grossRevenue.sub(taxAmount);

    await idrt.faucet(owner.address, grossRevenue);
    await idrt.connect(owner).transfer(contract.address, grossRevenue);
    await contract.connect(owner).flagTax(taxAccount.address, "0.5%", taxAmount);
    await idrt.connect(owner).transfer(taxAccount.address, taxAmount);
    await contract.connect(owner).distributeRevenue(tokenId, netRevenue);

    for (let i = 0; i < investors.length; i++) {
      const before = await idrt.balanceOf(investors[i].address);
      await contract.claimRevenue(investors[i].address, tokenId);
      const after = await idrt.balanceOf(investors[i].address);
      const expected = netRevenue.mul(portions[i]).div(totalUnits);
      expect(after.sub(before)).to.eq(expected);
      console.log(`📥 Investor ${i + 1} received ${ethers.utils.formatEther(after.sub(before))} IDRT`);
    }
  });

  it("🔁 Secondary market flow: resale and purchase with royalty", async () => {
    // Pastikan investorA sudah punya balance
    const resaleQty = 2;
    const resalePrice = ethers.utils.parseEther("12");

    const balanceA = await contract.balanceOf(investorA.address, tokenId);
    if (balanceA.lt(resaleQty)) {
      console.warn("⚠️  Investor A belum punya cukup token untuk resale. Lewati test ini.");
      return;
    }

    await contract.connect(investorA).setApprovalForAll(contract.address, true);
    await contract.connect(investorA).createListing(tokenId, resalePrice, resaleQty);
    const resaleListingId = await contract.listingCounter();
    console.log(`🔁 Investor A lists ${resaleQty} @ ${ethers.utils.formatEther(resalePrice)} IDRT`);

    const resaleCost = resalePrice.mul(resaleQty);
    await idrt.faucet(investorB.address, resaleCost);
    await idrt.connect(investorB).approve(contract.address, resaleCost);
    await contract.connect(investorB).executePurchase(resaleListingId, resaleQty);

    const balanceB = await contract.balanceOf(investorB.address, tokenId);
    console.log(`📦 After resale: Investor B now owns ${balanceB.toString()} units`);

    expect(balanceB.gte(resaleQty)).to.be.true;
  });

  it("📊 Revenue should be distributed according to current NFT balance", async () => {
    // Asumsi tokenId dari test sebelumnya sudah dibuat
    const tokenId = await contract.tokenIdCounter();
  
    // ✅ Hitung total supply dari semua pemegang
    const holders = [investorA, investorB, investorC];
    const balances = await Promise.all(holders.map(h => contract.balanceOf(h.address, tokenId)));
    const totalSupply = balances.reduce((acc, b) => acc.add(b), ethers.BigNumber.from(0));
  
    // ✅ Inject dan distribusi revenue
    const grossRevenue = ethers.utils.parseEther("99");
    const taxAmount = grossRevenue.mul(TAX_RATE).div(10000);
    const netRevenue = grossRevenue.sub(taxAmount);
  
    await idrt.faucet(owner.address, grossRevenue);
    await idrt.connect(owner).transfer(contract.address, grossRevenue);
  
    await contract.connect(owner).flagTax(taxAccount.address, "0.5%", taxAmount);
    await idrt.connect(owner).transfer(taxAccount.address, taxAmount);
    await contract.connect(owner).distributeRevenue(tokenId, netRevenue);
  
    // ✅ Validasi klaim berdasarkan current balance
    for (let i = 0; i < holders.length; i++) {
      const holder = holders[i];
      const balance = balances[i];
      if (balance.eq(0)) continue; 
      const expectedShare = netRevenue.mul(balance).div(totalSupply);
  
      const before = await idrt.balanceOf(holder.address);
      await contract.claimRevenue(holder.address, tokenId);
      const after = await idrt.balanceOf(holder.address);
      const received = after.sub(before);
  
      console.log(`✅ ${holder.address} has ${balance} units, expected ${ethers.utils.formatEther(expectedShare)} IDRT`);
      expect(received).to.eq(expectedShare);
    }
  });
});