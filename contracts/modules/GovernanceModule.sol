// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract GovernanceModule is Initializable, AccessControlUpgradeable {
    event GovernanceAction(
        address actor,
        bytes32 proposalId,
        string actionType,
        string module,
        string reason
    );
    event RegulatorView(address viewer, string logType);
    /// @notice Tracks which addresses have signed each proposal
    mapping(bytes32 => mapping(address => bool)) public signatures;

    function initializeGovernance() public virtual {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bytes32 public constant PLATFORM_MANAGER_ROLE = keccak256("PLATFORM_MANAGER_ROLE");

    function signProposal(bytes32 proposalId) external onlyRole(PLATFORM_MANAGER_ROLE) {
        require(!signatures[proposalId][msg.sender], "Already signed");
        signatures[proposalId][msg.sender] = true;
        emit GovernanceAction(msg.sender, proposalId, "SIGN_PROPOSAL", "", "Signed proposal");
    }

    function pauseModule(string memory module) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 proposalId = keccak256(abi.encodePacked("pause", module, block.timestamp));
        emit GovernanceAction(
            msg.sender,
            proposalId,
            "PAUSE_MODULE",
            module,
            string(abi.encodePacked("System paused: ", module))
        );
    }

    function regulatorAccess(address viewer, string memory logType)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit RegulatorView(viewer, logType);
    }

    function proposeUpgrade(bytes32 proposalId, string memory module, string memory reason)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit GovernanceAction(msg.sender, proposalId, "PROPOSE_UPGRADE", module, reason);
    }

    function logAuditEvent(string memory action, string memory reason) external onlyRole(PLATFORM_MANAGER_ROLE) {
        bytes32 proposalId = keccak256(abi.encodePacked(action, reason, block.timestamp));
        emit GovernanceAction(msg.sender, proposalId, action, "", reason);
    }
}