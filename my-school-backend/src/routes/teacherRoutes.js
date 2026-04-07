const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');

const {
  getTeacherInfo,
  getStudentsByClass,
  getAllStudents,
  addStudentsToClass,
  removeStudentFromClass,
  getLessons,
  addLesson,
  updateLesson,
  deleteLesson,
  getAgenda,
  addGrade,
  addAbsence
} = require('../controllers/teacherController');

const {
  saveSchedule,
  getSchedule
} = require('../controllers/scheduleController');

router.use(protect);

router.get('/info/:email', getTeacherInfo);
router.get('/students/:className', getStudentsByClass);
router.get('/students/all', getAllStudents);
router.post('/class/add-students', addStudentsToClass);
router.delete('/class/remove-student', removeStudentFromClass);
router.get('/lessons/:className', getLessons);
router.post('/lessons', addLesson);
router.put('/lessons/:id', updateLesson);
router.delete('/lessons/:id', deleteLesson);
router.get('/agenda/:className', getAgenda);
router.post('/schedule', saveSchedule);
router.get('/schedule/:className', getSchedule);
router.post('/grades', addGrade);
router.post('/absences', addAbsence);

module.exports = router;