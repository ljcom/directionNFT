// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract IdentityModule is Initializable, AccessControlUpgradeable {
    mapping(address => bytes32) public didHash;
    mapping(address => bool) public whitelisted;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event DIDRegistered(address indexed user, bytes32 did);
    event WhitelistUpdated(address indexed user, bool status);

    function initializeIdentity() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
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