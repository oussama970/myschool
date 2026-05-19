const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getConversations,
  getMessages,
  sendMessage,
  markAsRead,
  deleteMessage,
  getContacts
} = require('../controllers/messageController');

// Toutes les routes nécessitent une authentification
router.use(protect);

// Routes
router.get('/conversations', getConversations);
router.get('/messages/:contactId', getMessages);
router.post('/send', sendMessage);
router.put('/read/:messageId', markAsRead);
router.delete('/message/:messageId', deleteMessage);
router.get('/contacts', getContacts);

module.exports = router;