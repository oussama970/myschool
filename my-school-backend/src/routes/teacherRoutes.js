// backend/src/routes/teacherRoutes.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

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
  uploadFile,
  downloadFile,
  addGrade,
  addAbsence,
  getStudentGrades,
  getStudentAbsences,
  getStudentGradesAndAbsences,
  deleteGrade,
  deleteAbsence,
  updateTeacherProfile,
  changeTeacherPassword,
  getStudentDetails,
  getStudentGradesForParent,
  getStudentAbsencesForParent
} = require('../controllers/teacherController');

const {
  saveSchedule,
  getSchedule,
  getTeacherSchedule,
  getAllTeacherSchedules
} = require('../controllers/scheduleController');

const {
  getEventsByClass,
  addEvent,
  deleteEvent,
  getAllExamsByClass
} = require('../controllers/agendaEventController');

const {
  addExamGrade,
  getExamGrades
} = require('../controllers/examGradeController');

// ==================== NOUVEAU: IMPORT DES CONTROLLERS HOMEWORK ====================
const {
  getSubmissionsByLesson,
  gradeSubmission
} = require('../controllers/homeworkController');

// Middleware qui autorise teacher ET admin
const allowTeacherAndAdmin = (req, res, next) => {
  if (req.user && (req.user.role === 'teacher' || req.user.role === 'admin')) {
    next();
  } else {
    res.status(403).json({ success: false, message: 'Accès non autorisé' });
  }
};

// ==================== ROUTES ADMIN ====================
router.post('/create', createTeacher);
router.get('/all', getAllTeachers);
router.get('/list', getTeachersList);
router.delete('/:id', deleteTeacher);

// ==================== ROUTES ENSEIGNANT ====================

// Info enseignant
router.get('/info/:email', protect, getTeacherInfo);
router.get('/classes/:email', protect, getTeacherClasses);
router.get('/my-classes', protect, getTeacherClasses);
router.get('/notifications/:email', protect, getTeacherNotifications);

// Gestion des élèves
router.get('/students/:className', protect, getStudentsByClass);
router.get('/students/all', protect, getAllStudents);
router.post('/class/add-students', protect, addStudentsToClass);
router.delete('/class/remove-student', protect, removeStudentFromClass);

// ==================== ROUTES NOTES ET ABSENCES (LECTURE) ====================
router.get('/students/:studentId/grades', protect, getStudentGrades);
router.get('/students/:studentId/absences', protect, getStudentAbsences);
router.get('/students/:studentId/grades-absences', protect, getStudentGradesAndAbsences);

// ==================== ROUTES NOTES ET ABSENCES (ÉCRITURE) ====================
router.post('/grades', protect, addGrade);
router.post('/absences', protect, addAbsence);

// ==================== ROUTES NOTES ET ABSENCES (SUPPRESSION) ====================
router.delete('/grades/:id', protect, deleteGrade);
router.delete('/absences/:id', protect, deleteAbsence);

// ==================== ROUTES PROFIL ENSEIGNANT ====================
router.put('/profile', protect, updateTeacherProfile);
router.post('/change-password', protect, changeTeacherPassword);

// ==================== ROUTES POUR PARENT/ÉLÈVE (LECTURE SEULEMENT) ====================
router.get('/students/:studentId/details', protect, getStudentDetails);
router.get('/students/:studentId/grades-parent', protect, getStudentGradesForParent);
router.get('/students/:studentId/absences-parent', protect, getStudentAbsencesForParent);

// ==================== ROUTES LEÇONS ====================
router.get('/lessons/:className', protect, getLessons);
router.post('/lessons', protect, addLesson);
router.put('/lessons/:id', protect, updateLesson);
router.delete('/lessons/:id', protect, deleteLesson);
router.get('/agenda/:className', protect, getAgenda);

// ==================== ROUTES AGENDA (SCHEDULE) ====================
router.post('/schedule', protect, allowTeacherAndAdmin, saveSchedule);
router.get('/schedule/:className', protect, allowTeacherAndAdmin, getSchedule);
router.get('/schedule/teacher/:teacherEmail/:className', protect, getTeacherSchedule);
router.get('/schedule/teacher/:teacherEmail/all', protect, getAllTeacherSchedules);

// ==================== ROUTES AGENDA EVENTS (DEVOIRS/EXAMENS) ====================
router.get('/agenda-events/:className', protect, getEventsByClass);
router.post('/agenda-events', protect, addEvent);
router.delete('/agenda-events/:id', protect, deleteEvent);

// ✅ NOUVELLE ROUTE POUR LES PARENTS
router.get('/exams/:className', protect, getAllExamsByClass);

// ==================== ROUTES NOTES D'EXAMEN ====================
router.post('/exam-grades', protect, addExamGrade);
router.get('/exam-grades/:examId', protect, getExamGrades);

// ==================== ROUTES FICHIERS ====================
router.post('/upload', protect, upload.single('file'), uploadFile);
router.get('/download/:filename', protect, downloadFile);

// ==================== NOUVELLES ROUTES: SOUMISSIONS DEVOIRS ====================
// Enseignant: récupérer toutes les soumissions pour un devoir
router.get('/homework-submissions/:lessonId', protect, getSubmissionsByLesson);
// Enseignant: noter une soumission
router.post('/homework-submissions/:submissionId/grade', protect, gradeSubmission);

module.exports = router;