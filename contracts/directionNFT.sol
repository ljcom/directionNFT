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

    /// @notice Entry point for initializing all modules
    function initializeAll(string memory baseUri, address idrtAddress) public initializer {    
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        initializeIdentity();
        initializeToken(baseUri);
        initializeMarketplace();
        initializeEscrow(idrtAddress);
        initializeGovernance();
    }

    /// @notice Required for UUPS upgradeability
    function _authorizeUpgrade(address newImplementation) 
        internal override onlyRole(UPGRADER_ROLE) {}

    /// @notice ERC165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, TokenizationModule)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Required for MarketplaceModule to get IDRT ERC20 token
    function _getIDRT() internal view override returns (IERC20) {
        return idrtToken;
    }

    /// @notice Handles NFT transfer and registers the new holder
    function internalTransferNFT(address from, address to, uint256 tokenId, uint256 amount)
        internal
        override
    {
        emit TransferDebug("Before _safeTransferFrom", from, to, tokenId, amount);

        _safeTransferFrom(from, to, tokenId, amount, "");

        emit TransferDebug("After _safeTransferFrom", from, to, tokenId, amount);

        _registerHolder(tokenId, to);
    }

    /// @dev Debug event to trace NFT transfers
    event TransferDebug(string label, address from, address to, uint256 tokenId, uint256 amount);

    /// @notice Override to resolve conflict between Tokenization and Escrow modules
    function _registerHolder(uint256 tokenId, address holder)
        internal
        override(TokenizationModule, EscrowModule)
    {
        EscrowModule._registerHolder(tokenId, holder);
    }

    /// @notice Exposed balanceOf override (for ERC1155)
    function balanceOf(address user, uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable, EscrowModule)
        returns (uint256)
    {
        return super.balanceOf(user, tokenId);
    }

    /// @notice Returns metadata of a token (used by Marketplace and Tokenization)
    function getTokenMeta(uint256 tokenId)
        public
        view
        override(MarketplaceModule, TokenizationModule)
        returns (
            address propertyOwner,
            address fundManager,
            uint256 initialMintAmount,
            uint256 royaltyToOwner,
            uint256 royaltyToFundManager
        )
    {
        TokenMeta memory meta = tokenMeta[tokenId];
        return (
            meta.propertyOwner,
            meta.fundManager,
            meta.initialMintAmount,
            meta.royaltyToOwner,
            meta.royaltyToFundManager
        );
    }
}