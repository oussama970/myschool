const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getEventsByClass,
  createEvent,
  deleteEvent,
  respondToEvent,
  getEventsForParent
} = require('../controllers/eventController');

// Routes pour enseignant
router.get('/teacher/events/:className', protect, getEventsByClass);
router.post('/teacher/events', protect, createEvent);
router.delete('/teacher/events/:id', protect, deleteEvent);

// Routes pour parent
router.post('/parent/events/respond', protect, respondToEvent);
router.get('/parent/events/:studentId', protect, getEventsForParent);

module.exports = router;