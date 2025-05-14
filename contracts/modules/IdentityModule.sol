// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract IdentityModule is AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bytes32) public didHash;
    mapping(address => bool) public whitelisted;

    event DIDRegistered(address indexed user, bytes32 did);
    event WhitelistUpdated(address indexed user, bool status);

    function initializeIdentity() public virtual {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // ✅ Ganti dengan _grantRole
        _grantRole(ADMIN_ROLE, msg.sender);         // ✅ Ganti juga
    }

    function registerDID(address user, bytes32 did) external onlyRole(ADMIN_ROLE) {
        didHash[user] = did;
        emit DIDRegistered(user, did);
    }

    function setWhitelist(address user, bool status) external onlyRole(ADMIN_ROLE) {
        whitelisted[user] = status;
        emit WhitelistUpdated(user, status);
    }

    function isWhitelisted(address user) public view returns (bool) {
        return whitelisted[user];
    }
}