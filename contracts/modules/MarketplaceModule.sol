// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract MarketplaceModule is Initializable, AccessControlUpgradeable {
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

    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    event TokenListed(uint256 indexed listingId, address seller);
    event TokenSold(uint256 indexed listingId, address buyer);
    event ListingCancelled(uint256 indexed listingId);

    function initializeMarketplace() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(INVESTOR_ROLE, msg.sender);
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

    function executePurchase(uint256 listingId) external payable {
        Listing storage l = listings[listingId];
        require(l.active, "Inactive listing");
        require(msg.value >= l.price, "Insufficient payment");

        l.active = false;
        payable(l.seller).transfer(l.price);
        emit TokenSold(listingId, msg.sender);
    }
}