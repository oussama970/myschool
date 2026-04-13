const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');

const {
  createTeacher,
  getAllTeachers,
  getTeachersList,
  deleteTeacher
} = require('../controllers/teacherController');

const {
  createClass,
  getAllClasses,
  getClassesList,
  deleteClass
} = require('../controllers/classController');

const {
  getAllParents,
  deleteParent
} = require('../controllers/parentController');

const {
  getAllStudents,
  deleteStudent
} = require('../controllers/studentController');

const {
  getDashboardStats,
  getRecentActivities
} = require('../controllers/dashboardController');

const {
  getAdminProfile,
  updateAdminProfile,
  changeAdminPassword
} = require('../controllers/adminController');

// Toutes les routes nécessitent une authentification
router.use(protect);

// Dashboard
router.get('/dashboard/stats', getDashboardStats);
router.get('/recent-activities', getRecentActivities);

// Routes enseignants
router.post('/teachers', createTeacher);
router.get('/teachers', getAllTeachers);
router.get('/teachers/list', getTeachersList);
router.delete('/teachers/:id', deleteTeacher);

// Routes classes
router.post('/classes', createClass);
router.get('/classes', getAllClasses);
router.get('/classes/list', getClassesList);
router.delete('/classes/:id', deleteClass);

// Routes parents
router.get('/parents', getAllParents);
router.delete('/parents/:id', deleteParent);

// Routes élèves
router.get('/students', getAllStudents);
router.delete('/students/:id', deleteStudent);

// Routes profil admin
router.get('/profile/:email', getAdminProfile);
router.put('/profile', updateAdminProfile);
router.post('/change-password', changeAdminPassword);

module.exports = router;