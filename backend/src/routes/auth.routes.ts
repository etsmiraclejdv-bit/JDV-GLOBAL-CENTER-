import express from 'express';
const router = express.Router();

// POST /api/v1/auth/register
router.post('/register', (req, res) => {
  res.json({ message: 'Register endpoint - Coming soon' });
});

// POST /api/v1/auth/login
router.post('/login', (req, res) => {
  res.json({ message: 'Login endpoint - Coming soon' });
});

// POST /api/v1/auth/logout
router.post('/logout', (req, res) => {
  res.json({ message: 'Logout endpoint - Coming soon' });
});

// POST /api/v1/auth/refresh-token
router.post('/refresh-token', (req, res) => {
  res.json({ message: 'Refresh token endpoint - Coming soon' });
});

module.exports = router;
