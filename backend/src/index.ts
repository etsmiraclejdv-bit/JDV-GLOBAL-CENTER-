import express, { Express } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { AppDataSource } from './database/data-source';
import { errorHandler } from './middleware/error-handler';
import { logger } from './utils/logger';

// Load environment variables
dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// API v1 Routes
app.use('/api/v1/auth', require('./routes/auth.routes'));
app.use('/api/v1/users', require('./routes/user.routes'));
app.use('/api/v1/payments', require('./routes/payment.routes'));
app.use('/api/v1/wallets', require('./routes/wallet.routes'));

// Error handling
app.use(errorHandler);

// Initialize database and start server
AppDataSource.initialize()
  .then(() => {
    logger.info('Database connection established');
    
    app.listen(PORT, () => {
      logger.info(`🚀 Server is running on port ${PORT}`);
    });
  })
  .catch(error => {
    logger.error('Database connection failed:', error);
    process.exit(1);
  });

export default app;
