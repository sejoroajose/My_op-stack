// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./GovernanceToken.sol";

/// @title DAO
/// @notice A DAO contract for a crowdfunding platform using governance tokens.
contract DAO is Ownable {
    using SafeMath for uint256;

    GovernanceToken public governanceToken;

    // Campaign structure
    struct Campaign {
        address creator;
        string description;
        uint256 fundingGoal;
        uint256 deadline;
        uint256 totalContributions;
        address beneficiary;
        uint256 isWithdrawn;
        mapping(address => uint256) contributions;
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    Campaign[] public campaigns;

    // Events
    event CampaignCreated(uint256 indexed campaignId, address creator, string description, uint256 fundingGoal, uint256 deadline);
    event Contributed(uint256 indexed campaignId, address contributor, uint256 amount);
    event Voted(uint256 indexed campaignId, address voter, bool support);
    event CampaignFinalized(uint256 indexed campaignId, bool success);
    event Withdrawn(uint256 indexed campaignId, address beneficiary, uint256 amount);

    // Constructor
    constructor(address _governanceToken) {
        governanceToken = GovernanceToken(_governanceToken);
    }

    // Modifiers
    modifier campaignExists(uint256 campaignId) {
        require(campaignId < campaigns.length, "DAO: Campaign does not exist");
        _;
    }

    modifier campaignOpen(uint256 campaignId) {
        require(block.timestamp < campaigns[campaignId].deadline, "DAO: Campaign has ended");
        _;
    }

    modifier campaignClosed(uint256 campaignId) {
        require(block.timestamp >= campaigns[campaignId].deadline, "DAO: Campaign is still open");
        _;
    }

    modifier hasContributed(uint256 campaignId) {
        require(campaigns[campaignId].contributions[msg.sender] > 0, "DAO: No contribution made");
        _;
    }

    modifier hasNotVoted(uint256 campaignId) {
        require(!campaigns[campaignId].hasVoted[msg.sender], "DAO: Voter has already voted");
        _;
    }

    /// @notice Creates a new campaign.
    /// @param _description Description of the campaign.
    /// @param _fundingGoal Funding goal of the campaign.
    /// @param _deadline Deadline of the campaign.
    function createCampaign(string memory _description, uint256 _fundingGoal, uint256 _deadline) external {
        require(_deadline > block.timestamp, "DAO: Deadline must be in the future");
        require(_fundingGoal > 0, "DAO: Funding goal must be greater than zero");

        uint256 newCampaignId = campaigns.length;
        campaigns.push();
        Campaign storage newCampaign = campaigns[newCampaignId];
        newCampaign.creator = msg.sender;
        newCampaign.description = _description;
        newCampaign.fundingGoal = _fundingGoal;
        newCampaign.deadline = _deadline;

        emit CampaignCreated(newCampaignId, msg.sender, _description, _fundingGoal, _deadline);
    }

    /// @notice Contributes to a campaign.
    /// @param _campaignId ID of the campaign.
    function contribute(uint256 _campaignId) external payable campaignExists(_campaignId) campaignOpen(_campaignId) {
        require(msg.value > 0, "DAO: Contribution must be greater than zero");

        Campaign storage campaign = campaigns[_campaignId];
        campaign.contributions[msg.sender] = campaign.contributions[msg.sender].add(msg.value);
        campaign.totalContributions = campaign.totalContributions.add(msg.value);
        emit Contributed(_campaignId, msg.sender, msg.value);
    }

    /// @notice Votes on campaign proposal.
    /// @param _campaignId ID of the campaign
    /// @param _support True for supporting the beneficiary withdrawal, false for opposing.
    function vote(uint256 _campaignId, bool _support) external hasContributed(_campaignId) hasNotVoted(_campaignId) campaignClosed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        uint256 voterVotes = governanceToken.getVotes(msg.sender);

        if (_support) {
            campaign.votesFor = campaign.votesFor.add(voterVotes);
        } else {
            campaign.votesAgainst = campaign.votesAgainst.add(voterVotes);
        }

        campaign.hasVoted[msg.sender] = true;
        emit Voted(_campaignId, msg.sender, _support);
    }

    /// @notice Set the beneficiary address for a campaign.
    /// @param _campaignId ID of the campaign.
    /// @param _beneficiary The address that will receive the campaign funds
    function setBeneficiary(uint256 _campaignId, address _beneficiary) external campaignExists(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "DAO: Only the campaign Creator can set beneficiary");
        require(campaign.beneficiary == address(0), "DAO: Beneficiary already set");
        campaign.beneficiary = _beneficiary;
    }

    /// @notice Finalizes a campaign and allows the beneficiary to withdraw funds if the campaign is approved.
    /// @param _campaignId ID of the campaign.
    function finalizeCampaign(uint256 _campaignId) external campaignExists(_campaignId) campaignClosed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isWithdrawn == 0, "DAO: Campaign already finalized");
        require(campaign.beneficiary != address(0), "DAO: Beneficiary not set");

        bool success = (campaign.votesFor.mul(2) >= governanceToken.totalSupply() && campaign.votesFor >= campaign.votesAgainst) || campaign.totalContributions >= campaign.fundingGoal;

        if (success) {
            uint256 amount = campaign.totalContributions;
            (bool sent, ) = campaign.beneficiary.call{value: amount}("");
            require(sent, "DAO: Failed to send funds");
            emit Withdrawn(_campaignId, campaign.beneficiary, amount);
        }

        campaign.isWithdrawn = 1;
        emit CampaignFinalized(_campaignId, success);
    }

    /// @notice Allows contributors to withdraw their contributions if they wish to pull out.
    /// @param _campaignId ID of campaign.
    function withdrawContribution(uint256 _campaignId) external campaignExists(_campaignId) campaignOpen(_campaignId) hasContributed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "DAO: No contribution to withdraw");

        campaign.contributions[msg.sender] = 0;
        campaign.totalContributions = campaign.totalContributions.sub(contribution);
        (bool sent, ) = msg.sender.call{value: contribution}("");
        require(sent, "DAO: Failed to withdraw contribution");
        emit Contributed(_campaignId, msg.sender, contribution);
    }

    receive() external payable {}
}