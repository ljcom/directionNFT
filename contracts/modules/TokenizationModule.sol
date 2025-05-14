// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract TokenizationModule is ERC1155Upgradeable, AccessControlUpgradeable {
    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");
    bytes32 public constant NOTARY_ROLE = keccak256("NOTARY_ROLE");
    bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");

    uint256 public tokenIdCounter;
    mapping(uint256 => bytes32) public legalDocHash;
    mapping(uint256 => bool) public frozenToken;

    struct TokenMeta {
        address propertyOwner;
        address fundManager;
        uint256 initialMintAmount;
        uint256 royaltyToOwner;        // basis 10000 (misal 50 = 0.5%)
        uint256 royaltyToFundManager;  // basis 10000
    }

    mapping(uint256 => TokenMeta) public tokenMeta;

    event TokenIssued(uint256 indexed tokenId, uint256 amount, string uri);
    event TokenFrozen(uint256 indexed tokenId, bool frozen);
    event TokenBurned(address indexed from, uint256 tokenId, uint256 amount);

    function _registerHolder(uint256 tokenId, address holder) internal virtual;

    function initializeToken(string memory baseUri) public virtual {
        __ERC1155_init(baseUri);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FUND_MANAGER_ROLE, msg.sender);
        _grantRole(NOTARY_ROLE, msg.sender);
        _grantRole(PLATFORM_ROLE, msg.sender);
        //_grantRole(ESCROW_ROLE, msg.sender);
    }

    function mintToken(
        address to,
        uint256 amount,
        string memory uri,
        bytes32 docHash
    ) public onlyRole(FUND_MANAGER_ROLE) {
        uint256 id = ++tokenIdCounter;
        _mint(to, id, amount, "");
        legalDocHash[id] = docHash;

        // Simpan metadata default
        tokenMeta[id] = TokenMeta({
            propertyOwner: to,
            fundManager: msg.sender,
            initialMintAmount: amount,
            royaltyToOwner: 50,        // default 0.5%
            royaltyToFundManager: 50   // default 0.5%
        });

        emit TokenIssued(id, amount, uri);
        _registerHolder(id, to);
    }

    function freezeToken(uint256 tokenId, bool frozen) public onlyRole(DEFAULT_ADMIN_ROLE) {
        frozenToken[tokenId] = frozen;
        emit TokenFrozen(tokenId, frozen);
    }

    function burnToken(address from, uint256 tokenId, uint256 amount)
        public
        onlyRole(FUND_MANAGER_ROLE)
    {
        _burn(from, tokenId, amount);
        emit TokenBurned(from, tokenId, amount);
    }

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}