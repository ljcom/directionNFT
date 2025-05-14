// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract EscrowModule is Initializable, AccessControlUpgradeable {
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    IERC20 public idrtToken;
    mapping(address => uint256) public lockedFunds;

    // Revenue tracking
    mapping(uint256 => address[]) internal tokenHolders;
    mapping(uint256 => mapping(address => bool)) internal isHolder;
    mapping(uint256 => mapping(address => uint256)) public pendingRevenue;

    event FundsLocked(address indexed user, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event TaxFlagged(address indexed user, string taxType, uint256 value);
    event RevenueDistributed(uint256 tokenId, uint256 totalAmount);
    event RevenueClaimed(address indexed user, uint256 tokenId, uint256 amount);
    event HolderBalance(address indexed holder, uint256 balance);
    event RevenueAllocated(address indexed holder, uint256 share);
    
    function initializeEscrow(address tokenAddress) public virtual initializer {
        require(tokenAddress != address(0), "Invalid token");
        idrtToken = IERC20(tokenAddress);
        _grantRole(ESCROW_ROLE, msg.sender);
    }

    function lockFunds(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        idrtToken.transferFrom(msg.sender, address(this), amount);
        lockedFunds[msg.sender] += amount;
        emit FundsLocked(msg.sender, amount);
    }

    function releaseFunds(address to, uint256 amount) external onlyRole(ESCROW_ROLE) {
        require(lockedFunds[to] >= amount, "Insufficient balance");
        lockedFunds[to] -= amount;
        idrtToken.transfer(to, amount);
        emit FundsReleased(to, amount);
    }

    function flagTax(address user, string memory taxType, uint256 value) external onlyRole(ESCROW_ROLE) {
        emit TaxFlagged(user, taxType, value);
    }

    /// 🧠 Called from mintToken to register a holder
    function _registerHolder(uint256 tokenId, address holder) internal virtual {
        if (!isHolder[tokenId][holder]) {
            tokenHolders[tokenId].push(holder);
            isHolder[tokenId][holder] = true;
        }
    }

    /// 🧮 Distribute revenue based on token balance
    function distributeRevenue(uint256 tokenId, uint256 totalAmount) public onlyRole(ESCROW_ROLE) {
        require(totalAmount > 0, "Nothing to distribute");

        address[] memory holders = tokenHolders[tokenId];
        require(holders.length > 0, "No holders");

        uint256 totalSupply = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            uint256 bal = balanceOf(holders[i], tokenId);
            totalSupply += bal;
            emit HolderBalance(holders[i], bal);
        }

        require(totalSupply > 0, "Empty supply");

        for (uint256 i = 0; i < holders.length; i++) {
            address h = holders[i];
            uint256 bal = balanceOf(h, tokenId);
            if (bal > 0) {
                uint256 share = (totalAmount * bal) / totalSupply;
                pendingRevenue[tokenId][h] += share;
                emit RevenueAllocated(h, share);
            }
        }

        emit RevenueDistributed(tokenId, totalAmount);
    }

    /// 👛 Allow token holder to claim
    function claimRevenue(address user, uint256 tokenId) public {
        uint256 amount = pendingRevenue[tokenId][user];
        require(amount > 0, "No revenue");

        pendingRevenue[tokenId][user] = 0;
        idrtToken.transfer(user, amount);

        emit RevenueClaimed(user, tokenId, amount);
    }
    
    /// 🔍 Must be implemented in TokenizationModule
    function balanceOf(address user, uint256 tokenId) public view virtual returns (uint256);

}