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

    /// @notice Contributes to a campaign.
    /// @param _campaignId ID of the campaign.

    function contribute(uint256 _campaignId) external payable campaignExists(_campaignId) campaignOpen(_campaignId) {
        require(msg.value > 0, "BoostDAO: Contribution must be greater than zero");

        Campaign storage campaign = campaigns[_campaignId];
        campaign.contributions[msg.sender] = campaign.contributions[msg.sender].add(msg.value);
        emit Contributed(_campaignId, msg.sender, msg.value);
    }


    /// Votes on campaign proposal.
    /// @param _campaignId ID of the campaign
    /// @param _support True for supporting the beneficiary withdrawal, false for opposing.

    function vote(uint256 _campaignId, bool _support) external hasContributed(_campaignId) hasNotVoted(_campaignId) campaignClosed(_campaignId){
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

    /// Set the beneficiary address for a campaign.
    /// @param _campaignId of the campaign.
    /// @param _beneficiary The address that will recieve the campaign funds

    function setBeneficiary(uint256 _campaignId, address _beneficiary) external campaignExists(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "BoostDAO: Only the campaign Creator can set beneficiary");
        require(campaign.beneficiary == address(0), "BoostDAO: Beneficiary already set")
        campaign.beneficiary = _beneficiary;
    }


    /// @notice Finalizes a campaign and allows the beneficiary to withdraw funds in the campaign is approved.
    /// @param _campaignId ID of the campaign.

    function finalizeCampaign(uint256 _campaignId) external campaignExists(_campaignId) campaignClosed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.isWithdrawn, "BoostDAO: Campaign already finalized");


        bool success = (campaign.votesFor * 2 >= governanceToken.totalSupply() && campaign.votesFor >= campaign.votesAgainst) || campaign.totalContributions >= campaign.fundingGoal;

        if (success) {
            uint256 amount = campaign.totalContributions;
            (bool sent, ) = campaign.beneficiary.call{value: amount}("");
            require(sent, "BoostDAO: Failed to send funds");
            emit Withdrawn(_campaignId, campaign.beneficiary, amount);
        }

        campaign.isWithdrawn = true;
        emit CampaignFinalized(_campaignId, success);
    }


    /// @notice Allows contributors to withdraw their contributions if they wish to pull out.
    /// @param _capmpaignId ID of campaign.

    function withdrawContribution(uint256 _campaignId) external campaignExists(_campaignId) campaignOpen(_campaignId) hasContributed(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "BoostDAO: No contribution to withdraw");


        campaign.contributions[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: contribution}("");
        require(sent, "BoostDAO: Failed to withdraw contribution");
        emit Contributed(_campaignId, msg.sender, -int256(contribution));
    }

    receive() external payable{}

}

