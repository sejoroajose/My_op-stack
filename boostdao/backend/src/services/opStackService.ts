import { ethers, Contract, providers, Wallet } from 'ethers';
import DAO from '../../../frontend/store/DAO.';

interface Campaign {
  id: number;
  creator: string;
  description: string;
  fundingGoal: string;
  deadline: number;
  totalContributions: string;
}

class OPStackService {
  private l1Provider: providers.JsonRpcProvider;
  private l2Provider: providers.JsonRpcProvider;
  private wallet: Wallet;
  private daoContract: Contract;

  constructor() {
    this.l1Provider = new ethers.providers.JsonRpcProvider(process.env.L1_RPC_URL);
    this.l2Provider = new ethers.providers.JsonRpcProvider(process.env.OPTIMISM_SEPOLIA_RPC_URL);
    this.wallet = new ethers.Wallet(process.env.PRIVATE_KEY as string, this.l2Provider);
    this.daoContract = new ethers.Contract(process.env.DAO_ADDRESS as string, DAO.abi, this.wallet);
  }

  // Data Availability Layer
  async publishToDA(data: any): Promise<string> {
    const tx = await this.wallet.sendTransaction({
      to: process.env.DA_CONTRACT_ADDRESS,
      data: ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(data))),
    });
    await tx.wait();
    return tx.hash;
  }

  // Sequencing Layer
  async submitTransaction(method: string, params: any[]): Promise<string> {
    const tx = await this.daoContract[method](...params);
    await tx.wait();
    return tx.hash;
  }

  // Derivation Layer
  async deriveState(blockNumber: number): Promise<{ l1BlockHash: string; l2BlockHash: string; timestamp: number }> {
    const l1Block = await this.l1Provider.getBlock(blockNumber);
    const l2Block = await this.l2Provider.getBlock(blockNumber);

    return {
      l1BlockHash: l1Block.hash,
      l2BlockHash: l2Block.hash,
      timestamp: l2Block.timestamp,
    };
  }

  // Execution Layer
  async executeTransaction(txHash: string): Promise<boolean> {
    const receipt = await this.l2Provider.getTransactionReceipt(txHash);
    return receipt.status === 1;
  }

  // Settlement Layer
  async verifyStateRoot(blockNumber: number): Promise<string> {
    const l2BlockHeader = await this.l2Provider.send('eth_getBlockByNumber', [ethers.utils.hexValue(blockNumber), false]);
    return l2BlockHeader.stateRoot;
  }

  // DAO-specific methods
  async createCampaign(description: string, fundingGoal: string, deadline: number): Promise<string> {
    return this.submitTransaction('createCampaign', [description, ethers.utils.parseEther(fundingGoal), deadline]);
  }

  async contribute(campaignId: number, amount: string): Promise<string> {
    return this.submitTransaction('contribute', [campaignId], { value: ethers.utils.parseEther(amount) });
  }

  async getCampaigns(): Promise<Campaign[]> {
    const campaignCount = await this.daoContract.campaignCount();
    const campaigns: Campaign[] = [];

    for (let i = 0; i < campaignCount; i++) {
      const campaign = await this.daoContract.campaigns(i);
      campaigns.push({
        id: i,
        creator: campaign.creator,
        description: campaign.description,
        fundingGoal: ethers.utils.formatEther(campaign.fundingGoal),
        deadline: campaign.deadline.toNumber(),
        totalContributions: ethers.utils.formatEther(campaign.totalContributions),
      });
    }

    return campaigns;
  }
}

export default new OPStackService();
