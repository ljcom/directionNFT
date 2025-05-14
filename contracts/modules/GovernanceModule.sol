// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract GovernanceModule is Initializable, AccessControlUpgradeable {
    event GovernanceAction(string actionType, address actor, uint256 timestamp);
    event RegulatorView(address viewer, string logType);

    function initializeGovernance() public virtual {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pauseSystem(string memory module) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit GovernanceAction(
            string(abi.encodePacked("Pause-", module)),
            msg.sender,
            block.timestamp
        );
    }

    function regulatorAccess(address viewer, string memory logType)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit RegulatorView(viewer, logType);
    }
}