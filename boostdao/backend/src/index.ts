import express from 'express';
import cors from 'cors';
import daoRoutes from './routes/dao';

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/dao', daoRoutes);

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));