const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getProfile,
  getLinkedChildren
} = require('../controllers/userController');

router.get('/profile', protect, getProfile);
router.get('/children', protect, getLinkedChildren);

module.exports = router;