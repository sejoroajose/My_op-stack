import { NextApiRequest, NextApiResponse } from 'next';
import { ethers } from 'ethers';
import { abi as DAOAbi } from '../../contracts/DAO.json';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
    if (req.method !== 'POST') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    try {
        const { description, fundingGoal, deadline } = req.body;

        if (!description || !fundingGoal || !deadline) {
            return res.status(400).json({ message: 'Missing parameters' });
        }

        const provider = new ethers.providers.JsonRpcProvider(process.env.NEXT_PUBLIC_RPC_URL);
        const wallet = new ethers.Wallet(process.env.PRIVATE_KEY as string, provider);
        const daoContract = new ethers.Contract(process.env.DAO_CONTRACT_ADDRESS as string, DAOAbi, wallet);

        const tx = await daoContract.createCampaign(description, ethers.utils.parseUnits(fundingGoal, 'ether'), deadline);
        await tx.wait();

        res.status(200).json({ message: 'Campaign created successfully', txHash: tx.hash });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error creating campaign' });
    }
}
