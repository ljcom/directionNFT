// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TokenizationModule is Initializable, ERC1155Upgradeable, AccessControlUpgradeable {
    uint256 public tokenIdCounter;
    mapping(uint256 => bytes32) public legalDocHash;
    mapping(uint256 => bool) public frozenToken;

    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");

    event TokenIssued(uint256 indexed tokenId, uint256 amount, string uri);
    event TokenFrozen(uint256 indexed tokenId, bool frozen);
    event TokenBurned(address indexed from, uint256 tokenId, uint256 amount);

    function initializeToken(string memory baseUri) public initializer {
        __ERC1155_init(baseUri);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FUND_MANAGER_ROLE, msg.sender);
    }

    function mintToken(address to, uint256 amount, string memory uri, bytes32 docHash)
        public
        onlyRole(FUND_MANAGER_ROLE)
    {
        uint256 id = ++tokenIdCounter;
        _mint(to, id, amount, "");
        legalDocHash[id] = docHash;
        emit TokenIssued(id, amount, uri);
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
}