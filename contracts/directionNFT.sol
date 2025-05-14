// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Import modules
import "./modules/IdentityModule.sol";
import "./modules/TokenizationModule.sol";
import "./modules/MarketplaceModule.sol";
import "./modules/EscrowModule.sol";
import "./modules/GovernanceModule.sol";

contract DirectionNFT is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IdentityModule,
    TokenizationModule,
    MarketplaceModule,
    EscrowModule,
    GovernanceModule
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initializeAll(string memory baseUri) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        // Initialize all modules
        initializeIdentity();
        initializeToken(baseUri);
        initializeMarketplace();
        initializeEscrow();
        initializeGovernance();
    }

    // Required for UUPS upgradeability
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}