const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("DirectionNFT", function () {
  let DirectionNFT, contract, owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    DirectionNFT = await ethers.getContractFactory("DirectionNFT");
    contract = await upgrades.deployProxy(DirectionNFT, ["https://example.com/"], {
      initializer: "initializeAll",
    });
    await contract.deployed();
  });

  it("should initialize and grant roles", async function () {
    expect(await contract.hasRole(await contract.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
  });

  it("should register a DID and whitelist user", async function () {
    const did = ethers.utils.formatBytes32String("user1-did");
    await contract.registerDID(user1.address, did);
    expect(await contract.didHash(user1.address)).to.equal(did);

    await contract.setWhitelist(user1.address, true);
    expect(await contract.isWhitelisted(user1.address)).to.equal(true);
  });

  it("should mint token and record hash", async function () {
    const docHash = ethers.utils.formatBytes32String("legal-doc-123");
    const uri = "https://example.com/token/1";

    await contract.mintToken(user1.address, 10, uri, docHash);
    const tokenId = await contract.tokenIdCounter();

    expect(await contract.legalDocHash(tokenId)).to.equal(docHash);
    const balance = await contract.balanceOf(user1.address, tokenId);
    expect(balance.eq(10)).to.be.true;
  });

  it("should lock and release escrow", async function () {
    const amount = ethers.utils.parseEther("1");
  
    await contract.connect(user1).lockFunds({ value: amount });
  
    const lockedBefore = await contract.lockedFunds(user1.address);
    expect(lockedBefore).to.be.deep.equal(amount);
  
    await contract.releaseFunds(user1.address, amount);
  
    const lockedAfter = await contract.lockedFunds(user1.address);
    expect(lockedAfter.eq(0)).to.be.true;
  });
});