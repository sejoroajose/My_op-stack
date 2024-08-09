// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GovernanceToken.sol";

contract MintManager is Ownable {
    GovernanceToken public immutable governanceToken;

    uint256 public constant MINT_CAP = 20; // 2%
    uint256 public constant DENOMINATOR = 1000;
    uint256 public constant MINT_PERIOD = 365 days;

    uint256 public mintPermittedAfter;

    constructor(address _upgrader, address _governanceToken) Ownable(_upgrader) {
    governanceToken = GovernanceToken(_governanceToken);
}

    function mint(address _account, uint256 _amount) public onlyOwner {
        if (mintPermittedAfter > 0) {
            require(mintPermittedAfter <= block.timestamp, "MintManager: minting not permitted yet");
            require(_amount <= (governanceToken.totalSupply() * MINT_CAP) / DENOMINATOR, "MintManager: mint amount exceeds cap");
        }

        mintPermittedAfter = block.timestamp + MINT_PERIOD;
        governanceToken.mint(_account, _amount);
    }

    function upgrade(address _newMintManager) public onlyOwner {
        require(_newMintManager != address(0), "MintManager: mint manager cannot be the zero address");
        governanceToken.transferOwnership(_newMintManager);
    }
}
