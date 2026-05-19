const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getParentChildren,
  linkChildToParent,
  getChildLessons,
  getChildGrades,
  getChildExamGrades,
  getChildAbsences,
  getChildEvents,
  parentRespondToEvent,
  getChildTeachers,
  getParentConversations,
  sendParentMessage
} = require('../controllers/parentController');

// Toutes les routes nécessitent une authentification
router.use(protect);

// ==================== ENFANTS ====================
router.get('/children/:email', getParentChildren);
router.post('/link-child', linkChildToParent);

// ==================== COURS ET DEVOIRS ====================
router.get('/child/:childId/lessons', getChildLessons);

// ==================== NOTES ====================
router.get('/child/:childId/grades', getChildGrades);
router.get('/child/:childId/exam-grades', getChildExamGrades);

// ==================== ABSENCES ====================
router.get('/child/:childId/absences', getChildAbsences);

// ==================== ÉVÉNEMENTS ====================
router.get('/child/:childId/events', getChildEvents);
router.post('/events/respond', parentRespondToEvent);

// ==================== ENSEIGNANTS ====================
router.get('/child/:childId/teachers', getChildTeachers);

// ==================== MESSAGES ====================
router.get('/conversations/:parentId', getParentConversations);
router.post('/send-message', sendParentMessage);

module.exports = router;