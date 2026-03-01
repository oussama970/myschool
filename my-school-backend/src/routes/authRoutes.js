const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  register,
  verifyEmail,
  login,
  verifyParentCode,
  getChildInfo,
  getLinkedChild,
  getParentChildren,
  forgotPassword,
  resetPassword
} = require('../controllers/authController');

// Routes publiques (sans authentification)
router.post('/register', register);
router.post('/verify-email', verifyEmail);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Routes GET publiques
router.get('/child/:email', getChildInfo);
router.get('/parent-children/:email', getParentChildren);
router.get('/linked-child/:email', getLinkedChild);

// Routes protégées (nécessitent un token)
router.post('/verify-parent-code', protect, verifyParentCode);

// Route de test
router.get('/test', (req, res) => {
  res.json({ message: 'Route auth fonctionne' });
});

module.exports = router;