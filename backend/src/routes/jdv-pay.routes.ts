import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { JDVPayService } from '../services/jdv-pay.service';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';
import { logger } from '../utils/logger';

const router = express.Router();
const jdvPayService = new JDVPayService();

// GET /api/v1/jdv-pay/balance/:userId
router.get('/balance/:userId', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const currency = (req.query.currency as string) || 'XOF';
    const balance = await jdvPayService.getBalance(req.params.userId, currency);
    res.json({ success: true, data: balance });
  } catch (error: any) {
    logger.error('Get balance error:', error);
    res.status(400).json({
      success: false,
      error: { message: error.message, code: 'GET_BALANCE_FAILED' },
    });
  }
});

// POST /api/v1/jdv-pay/qr-code/generate
router.post(
  '/qr-code/generate',
  authMiddleware,
  [body('amount').isFloat({ min: 0.01 })],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { amount, currency = 'XOF' } = req.body;
      const qrCode = await jdvPayService.generateQRCode(req.user.id, amount, currency);
      res.status(201).json({ success: true, data: qrCode });
    } catch (error: any) {
      logger.error('Generate QR code error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'QR_GENERATION_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/qr-code/scan
router.post(
  '/qr-code/scan',
  authMiddleware,
  [
    body('qrCode').notEmpty(),
    body('amount').isFloat({ min: 0.01 }),
  ],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { qrCode, amount, currency = 'XOF' } = req.body;
      const transaction = await jdvPayService.scanQRCode(req.user.id, qrCode, amount, currency);
      res.status(201).json({ success: true, data: transaction });
    } catch (error: any) {
      logger.error('Scan QR code error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'QR_SCAN_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/beneficiaries
router.post(
  '/beneficiaries',
  authMiddleware,
  [
    body('name').notEmpty(),
    body('phone').notEmpty(),
    body('email').isEmail(),
  ],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const beneficiary = await jdvPayService.addBeneficiary(req.user.id, req.body);
      res.status(201).json({ success: true, data: beneficiary });
    } catch (error: any) {
      logger.error('Add beneficiary error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'ADD_BENEFICIARY_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/invoices
router.post(
  '/invoices',
  authMiddleware,
  [body('amount').isFloat({ min: 0.01 })],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const invoice = await jdvPayService.createInvoice(req.user.id, req.body);
      res.status(201).json({ success: true, data: invoice });
    } catch (error: any) {
      logger.error('Create invoice error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'CREATE_INVOICE_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/invoices/:invoiceId/send
router.post(
  '/invoices/:invoiceId/send',
  authMiddleware,
  [body('recipientEmail').isEmail()],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const result = await jdvPayService.sendInvoice(req.params.invoiceId, req.body.recipientEmail);
      res.json({ success: true, data: result });
    } catch (error: any) {
      logger.error('Send invoice error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'SEND_INVOICE_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/recurring
router.post(
  '/recurring',
  authMiddleware,
  [
    body('amount').isFloat({ min: 0.01 }),
    body('frequency').notEmpty(),
  ],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const recurring = await jdvPayService.setupRecurringPayment(req.user.id, req.body);
      res.status(201).json({ success: true, data: recurring });
    } catch (error: any) {
      logger.error('Setup recurring payment error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'RECURRING_SETUP_FAILED' },
      });
    }
  }
);

// GET /api/v1/jdv-pay/transactions
router.get('/transactions', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const filters = {
      type: req.query.type,
      status: req.query.status,
      currency: req.query.currency,
      startDate: req.query.startDate,
      endDate: req.query.endDate,
      limit: parseInt(req.query.limit as string) || 50,
    };

    const transactions = await jdvPayService.getTransactionHistory(req.user.id, filters);
    res.json({ success: true, data: transactions });
  } catch (error: any) {
    logger.error('Get transactions error:', error);
    res.status(400).json({
      success: false,
      error: { message: error.message, code: 'GET_TRANSACTIONS_FAILED' },
    });
  }
});

// GET /api/v1/jdv-pay/statistics
router.get('/statistics', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const period = (req.query.period as string) || 'month';
    const stats = await jdvPayService.getStatistics(req.user.id, period);
    res.json({ success: true, data: stats });
  } catch (error: any) {
    logger.error('Get statistics error:', error);
    res.status(400).json({
      success: false,
      error: { message: error.message, code: 'GET_STATISTICS_FAILED' },
    });
  }
});

// POST /api/v1/jdv-pay/convert
router.post(
  '/convert',
  authMiddleware,
  [
    body('amount').isFloat({ min: 0.01 }),
    body('fromCurrency').notEmpty(),
    body('toCurrency').notEmpty(),
  ],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { amount, fromCurrency, toCurrency } = req.body;
      const result = await jdvPayService.convertCurrency(amount, fromCurrency, toCurrency);
      res.json({ success: true, data: result });
    } catch (error: any) {
      logger.error('Currency conversion error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'CONVERSION_FAILED' },
      });
    }
  }
);

// POST /api/v1/jdv-pay/refund
router.post(
  '/refund',
  authMiddleware,
  [
    body('transactionId').notEmpty(),
    body('reason').notEmpty(),
  ],
  async (req: AuthRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { transactionId, reason } = req.body;
      const refund = await jdvPayService.refundPayment(transactionId, reason);
      res.json({ success: true, data: refund });
    } catch (error: any) {
      logger.error('Refund payment error:', error);
      res.status(400).json({
        success: false,
        error: { message: error.message, code: 'REFUND_FAILED' },
      });
    }
  }
);

module.exports = router;
