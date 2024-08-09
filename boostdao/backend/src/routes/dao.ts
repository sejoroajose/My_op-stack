import express from 'express';
import daoService from '../services/daoService';

const router = express.Router();

router.post('/create-campaign', async (req: express.Request, res: express.Response) => {
  try {
    const result = await daoService.createCampaign(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

router.post('/contribute', async (req: express.Request, res: express.Response) => {
  try {
    const result = await daoService.contribute(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

router.get('/campaigns', async (req: express.Request, res: express.Response) => {
  try {
    const campaigns = await daoService.getCampaigns();
    res.json(campaigns);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
});

export default router;