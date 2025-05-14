# DirectionNFT

**DirectionNFT** is a modular, upgradeable smart contract system for compliant tokenization of real estate assets in Indonesia. It is built using the UUPS proxy pattern and supports full regulatory alignment under OJK’s regulatory sandbox (IKD). The platform enables secure issuance, trading, governance, and distribution of property-backed NFTs using blockchain technology.

---

## 🧱 Architecture Overview

DirectionNFT consists of the following upgradeable modules:

- 🔐 **IdentityModule** – DID issuance, role-based access control, whitelist enforcement.
- 🏠 **TokenizationModule** – ERC-1155 real estate tokens with legal document binding and freeze/burn lifecycle support.
- 🛒 **MarketplaceModule** – Peer-to-peer listing, purchase, and compliance-checked trading.
- 💰 **EscrowModule** – Fiat/stablecoin locking, fund release, and revenue distribution with tax hooks.
- 🏛️ **GovernanceModule** – Emergency control, role escalation, and on-chain audit logging.

Main contract: `DirectionNFT.sol` integrates all modules under a UUPS upgradeable proxy system.

---

## 🚀 Features

- ✅ KYC-integrated DID and role binding (via `e-KTP` or passport)
- ✅ ERC-1155 token issuance for property shares
- ✅ Regulatory whitelist enforcement (OJK, DJP, Bappebti aligned)
- ✅ On-chain escrow, distribution, and compliance event logs
- ✅ Sandbox-ready and modular

---

## 📦 Getting Started

### Requirements

- Node.js (v18+)
- Hardhat
- OpenZeppelin Contracts + Upgrades plugin

### Installation

```bash
git clone https://github.com/ljcom/directionNFT.git
cd directionNFT
npm install