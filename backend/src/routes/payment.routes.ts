import express from 'express';
const router = express.Router();

// POST /api/v1/payments
router.post('/', (req, res) => {
  res.json({ message: 'Create payment endpoint - Coming soon' });
});

// GET /api/v1/payments/:id
router.get('/:id', (req, res) => {
  res.json({ message: 'Get payment endpoint - Coming soon' });
});

// GET /api/v1/payments
router.get('/', (req, res) => {
  res.json({ message: 'List payments endpoint - Coming soon' });
});

module.exports = router;
