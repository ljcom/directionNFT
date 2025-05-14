// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract MarketplaceModule is Initializable, AccessControlUpgradeable {
    struct Listing {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        bool active;
    }

    uint256 public listingCounter;
    mapping(uint256 => Listing) public listings;

    //IERC20 public idrtToken;
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    event TokenListed(uint256 indexed listingId, address seller);
    event TokenSold(uint256 indexed listingId, address buyer);
    event ListingCancelled(uint256 indexed listingId);

    

    function initializeMarketplace() public virtual {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INVESTOR_ROLE, msg.sender);
    }

    function createListing(uint256 tokenId, uint256 price, uint256 quantity) external {
        uint256 id = ++listingCounter;
        listings[id] = Listing(id, msg.sender, tokenId, price, quantity, true);
        emit TokenListed(id, msg.sender);
    }

    function cancelListing(uint256 listingId) external {
        Listing storage l = listings[listingId];
        require(l.seller == msg.sender, "Not your listing");
        l.active = false;
        emit ListingCancelled(listingId);
    }

    function _getIDRT() internal view virtual returns (IERC20);

    function getTokenMeta(uint256 tokenId)
    public
    view
    virtual
    returns (
        address propertyOwner,
        address fundManager,
        uint256 initialMintAmount,
        uint256 royaltyToOwner,
        uint256 royaltyToFundManager
    );

    function internalTransferNFT(address from, address to, uint256 tokenId, uint256 amount) internal virtual;

    function executePurchase(uint256 listingId, uint256 quantityToBuy) external {
        Listing storage l = listings[listingId];
        require(l.active, "Inactive listing");
        require(quantityToBuy > 0 && quantityToBuy <= l.quantity, "Invalid quantity");

        uint256 totalPrice = l.price * quantityToBuy;
        IERC20 token = _getIDRT();

        (
            address propertyOwner,
            address fundManager,
            ,
            uint256 royaltyToOwner,
            uint256 royaltyToFundMgr
        ) = getTokenMeta(l.tokenId);

        uint256 royaltyOwnerAmount = (totalPrice * royaltyToOwner) / 10000;
        uint256 royaltyFundAmount = (totalPrice * royaltyToFundMgr) / 10000;
        uint256 payoutToSeller = totalPrice - royaltyOwnerAmount - royaltyFundAmount;

        // Transfer IDRT from buyer to contract
        require(token.transferFrom(msg.sender, address(this), totalPrice), "Transfer to contract failed");

        // Distribute to parties
        if (royaltyOwnerAmount > 0) {
            require(token.transfer(propertyOwner, royaltyOwnerAmount), "Royalty to owner failed");
        }

        if (royaltyFundAmount > 0) {
            require(token.transfer(fundManager, royaltyFundAmount), "Royalty to fundManager failed");
        }

        require(token.transfer(l.seller, payoutToSeller), "Payout to seller failed");

        // Transfer NFT
        internalTransferNFT(l.seller, msg.sender, l.tokenId, quantityToBuy);

        // Update listing quantity
        l.quantity -= quantityToBuy;
        if (l.quantity == 0) {
            l.active = false;
        }

        emit TokenSold(listingId, msg.sender);
    }
}