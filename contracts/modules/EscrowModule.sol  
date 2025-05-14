// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract EscrowModule is Initializable, AccessControlUpgradeable {
    mapping(address => uint256) public lockedFunds;

    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    event FundsLocked(address indexed payer, uint256 amount);
    event FundsReleased(address indexed payee, uint256 amount);
    event TaxFlagged(address indexed user, string taxType, uint256 value);

    function initializeEscrow() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ESCROW_ROLE, msg.sender);
    }

    function lockFunds() external payable {
        lockedFunds[msg.sender] += msg.value;
        emit FundsLocked(msg.sender, msg.value);
    }

    function releaseFunds(address payable recipient, uint256 amount)
        public
        onlyRole(ESCROW_ROLE)
    {
        require(lockedFunds[recipient] >= amount, "Insufficient balance");
        lockedFunds[recipient] -= amount;
        recipient.transfer(amount);
        emit FundsReleased(recipient, amount);
    }

    function flagTax(address user, string memory taxType, uint256 value)
        public
        onlyRole(ESCROW_ROLE)
    {
        emit TaxFlagged(user, taxType, value);
    }

    receive() external payable {}
}