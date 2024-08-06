// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./GovernanceToken.sol";

// Mock World ID verification interface
interface IWorldID {
    function isVerified(address _user) external view returns (bool);
}

/// @title DAO
/// @notice A DAO contract for a crowdfunding platform using governance tokens and World ID verification.
contract DAO is Ownable {
    using SafeMath for unit256;

    GovernanceToken public governanceToken;
    IWorldID public worldID;


    //Campaign structure
    struct Campaign {
        address creator;
        string description;
        uint256 fundingGoal;
        uint256 deadline;
        uint256 totalContributions;
        address beneficiary;
        bool isVerified;
        bool isWithdrawn;
        mapping(address => uint256) contributions;
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
    }


    Campaign[] public campaigns;

    //Events Creation
    event CampaignCreated(uint256 indexed campaignId, address creator, string description, uint256 fundingGoal, uint256 deadline);
    event Contributed(uint256 indexed campaignId, address contributor, uint256 amount);
    event Voted(uint256 indexed campaignId, address voter, bool support);
    event CampaignFinalized(uint256 indexed campaignId, bool success);
    event Withdrawn(uint256 indexed campaignId, address beneficiary, uint256 amount);

    // Modifiers
    modifier onlyVerified() {
        required(worldID.isVerified(msg.sender), "BoostDAO: User is not verified");
        _;
    }

    modifier campaignExists(uint256 campaignId) {
        require(campaignId < campaigns.length, "BoostDAO: Campaign does not exist")
        _;
    }

    modifier campaignOpen(uint256 campaignId) {
        require(block.timestamp < campaigns[campaignId].deadline, "BoostDAO: Campaign has ended");
        _;
    }

    modifier campaignClosed(uint256 campaignId) {
        require(block.timestamp >= campaigns[campaignId], "BoostDAO: Campaign is still open");
        _;
    }

    modifier hasContributed(uint256 campaignId) {
        require(campaigns[campaignId].contributions[msg.sender] > 0, "BoostDAO: No contribution made");
        _;
    }

    modifier hasNotVoted(uint256 campaignId) {
        require(!campaigns[campaignId].hasVoted[msg.sender], "BoostDAO: Voter has already voted");
        _;
    }

}

