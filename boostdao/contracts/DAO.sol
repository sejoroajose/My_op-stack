// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./GovernanceToken.sol";

contract DAO is Ownable {
    GovernanceToken public governanceToken;

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

    event CampaignCreated(uint256 indexed campaignId, address creator, string description, uint256 fundingGoal, uint256 deadline, address beneficiary);
    event Contributed(uint256 indexed campaignId, address contributor, uint256 amount);
    event Voted(uint256 indexed campaignId, address voter, bool support);
    event CampaignFinalized(uint256 indexed campaignId, bool success);
    event Withdrawn(uint256 indexed campaignId, address beneficiary, uint256 amount);

    constructor(address _governanceToken) Ownable(msg.sender) {
    governanceToken = GovernanceToken(_governanceToken);
}

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

    function createCampaign(string memory _description, uint256 _fundingGoal, uint256 _deadline, address _beneficiary) external {
        require(_deadline > block.timestamp, "DAO: Deadline must be in the future");
        require(_fundingGoal > 0, "DAO: Funding goal must be greater than zero");
        require(_beneficiary != address(0), "DAO: Beneficiary address cannot be zero");

        uint256 newCampaignId = campaigns.length;
        campaigns.push();
        Campaign storage newCampaign = campaigns[newCampaignId];
        newCampaign.creator = msg.sender;
        newCampaign.description = _description;
        newCampaign.fundingGoal = _fundingGoal;
        newCampaign.deadline = _deadline;
        newCampaign.beneficiary = _beneficiary;

        emit CampaignCreated(newCampaignId, msg.sender, _description, _fundingGoal, _deadline, _beneficiary);
    }

    function contribute(uint256 _campaignId) external payable campaignExists(_campaignId) campaignOpen(_campaignId) {
        require(msg.value > 0, "DAO: Contribution must be greater than zero");

        Campaign storage campaign = campaigns[_campaignId];
        campaign.contributions[msg.sender] += msg.value;
        campaign.totalContributions += msg.value;
        emit Contributed(_campaignId, msg.sender, msg.value);
    }

    function vote(uint256 _campaignId, bool _support) external hasContributed(_campaignId) hasNotVoted(_campaignId) campaignClosed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        uint256 voterVotes = governanceToken.getVotes(msg.sender);

        if (_support) {
            campaign.votesFor += voterVotes;
        } else {
            campaign.votesAgainst += voterVotes;
        }

        campaign.hasVoted[msg.sender] = true;
        emit Voted(_campaignId, msg.sender, _support);
    }


    function finalizeCampaign(uint256 _campaignId) external campaignExists(_campaignId) campaignClosed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isWithdrawn == 0, "DAO: Campaign already finalized");
        require(campaign.beneficiary != address(0), "DAO: Beneficiary not set");

        bool success = (campaign.votesFor * 2 >= governanceToken.totalSupply() && campaign.votesFor >= campaign.votesAgainst) || campaign.totalContributions >= campaign.fundingGoal;

        if (success) {
            uint256 amount = campaign.totalContributions;
            (bool sent, ) = campaign.beneficiary.call{value: amount}("");
            require(sent, "DAO: Failed to send funds");
            emit Withdrawn(_campaignId, campaign.beneficiary, amount);
        }

        campaign.isWithdrawn = 1;
        emit CampaignFinalized(_campaignId, success);
    }

    function withdrawContribution(uint256 _campaignId) external campaignExists(_campaignId) campaignOpen(_campaignId) hasContributed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "DAO: No contribution to withdraw");

        campaign.contributions[msg.sender] = 0;
        campaign.totalContributions -= contribution;
        (bool sent, ) = msg.sender.call{value: contribution}("");
        require(sent, "DAO: Failed to withdraw contribution");
        emit Contributed(_campaignId, msg.sender, contribution);
    }

    receive() external payable {}
}
