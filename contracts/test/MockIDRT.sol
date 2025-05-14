// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockIDRT is ERC20 {
    constructor() ERC20("IDRT", "IDRT") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}