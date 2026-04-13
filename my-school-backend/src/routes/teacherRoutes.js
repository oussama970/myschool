const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');

const {
  createTeacher,
  getAllTeachers,
  getTeachersList,
  deleteTeacher,
  getTeacherInfo,
  getTeacherClasses,
  getTeacherNotifications,
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

// ==================== ROUTES ADMIN ====================
router.post('/create', createTeacher);
router.get('/all', getAllTeachers);
router.get('/list', getTeachersList);
router.delete('/:id', deleteTeacher);

// ==================== ROUTES ENSEIGNANT ====================
router.get('/info/:email', protect, getTeacherInfo);
router.get('/classes/:email', protect, getTeacherClasses);
router.get('/my-classes', protect, getTeacherClasses);
router.get('/notifications/:email', protect, getTeacherNotifications);
router.get('/students/:className', protect, getStudentsByClass);
router.get('/students/all', protect, getAllStudents);
router.post('/class/add-students', protect, addStudentsToClass);
router.delete('/class/remove-student', protect, removeStudentFromClass);
router.get('/lessons/:className', protect, getLessons);
router.post('/lessons', protect, addLesson);
router.put('/lessons/:id', protect, updateLesson);
router.delete('/lessons/:id', protect, deleteLesson);
router.get('/agenda/:className', protect, getAgenda);
router.post('/schedule', protect, saveSchedule);
router.get('/schedule/:className', protect, getSchedule);
router.post('/grades', protect, addGrade);
router.post('/absences', protect, addAbsence);

module.exports = router;