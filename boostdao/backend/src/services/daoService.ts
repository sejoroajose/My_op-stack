import opStackService from './opStackService';

async function createCampaign(campaignData: {
  description: string;
  fundingGoal: string;
  deadline: string;
}) {
  const txHash = await opStackService.createCampaign(
    campaignData.description,
    campaignData.fundingGoal,
    campaignData.deadline
  );

  // ... (same logic as in the previous version)
}

async function contribute(contributionData: { campaignId: number; amount: string }) {
  const txHash = await opStackService.contribute(contributionData.campaignId, contributionData.amount);

  // ... (same logic as in the previous version)
}

async function getCampaigns() {
  return opStackService.getCampaigns();
}

export default {
  createCampaign,
  contribute,
  getCampaigns,
};