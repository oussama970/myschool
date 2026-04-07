const User = require('../models/User');
const Class = require('../models/Class');
const Lesson = require('../models/Lesson');
const bcrypt = require('bcryptjs');
const { sendTeacherCredentialsEmail } = require('../utils/emailService');

// ==================== FONCTIONS POUR ADMIN ====================

const createTeacher = async (req, res) => {
  try {
    const { fullName, email, password, phoneNumber, subjects, classes, sendEmail } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
        success: false,
        message: 'Cet email est déjà utilisé' 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const teacher = await User.create({
      fullName,
      email: email.toLowerCase(),
      password: hashedPassword,
      role: 'teacher',
      isVerified: true,
      phoneNumber: phoneNumber || '',
      subjects: subjects || [],
      assignedClasses: classes || []
    });

    if (classes && classes.length > 0) {
      for (const className of classes) {
        await Class.findOneAndUpdate(
          { name: className },
          { 
            $set: { 
              teacherId: teacher._id,
              teacherName: teacher.fullName 
            } 
          }
        );
      }
    }

    if (sendEmail) {
      try {
        await sendTeacherCredentialsEmail(email, fullName, password);
      } catch (emailError) {
        console.error('Erreur envoi email:', emailError.message);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Enseignant créé avec succès',
      teacher: {
        id: teacher._id,
        fullName: teacher.fullName,
        email: teacher.email,
        phoneNumber: teacher.phoneNumber,
        subjects: teacher.subjects,
        assignedClasses: teacher.assignedClasses
      }
    });
  } catch (error) {
    console.error('Erreur création enseignant:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getAllTeachers = async (req, res) => {
  try {
    const teachers = await User.find({ role: 'teacher' }).select('-password').sort('-createdAt');
    res.json({ success: true, teachers: teachers });
  } catch (error) {
    console.error('Erreur récupération enseignants:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getTeachersList = async (req, res) => {
  try {
    const teachers = await User.find({ role: 'teacher' }).select('fullName');
    const teacherNames = teachers.map(t => t.fullName);
    res.json({ success: true, teachers: teacherNames });
  } catch (error) {
    console.error('Erreur récupération liste enseignants:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const deleteTeacher = async (req, res) => {
  try {
    const teacher = await User.findById(req.params.id);
    if (!teacher || teacher.role !== 'teacher') {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    await Class.updateMany({ teacherId: teacher._id }, { $set: { teacherId: null, teacherName: '' } });
    await teacher.deleteOne();
    res.json({ success: true, message: 'Enseignant supprimé avec succès' });
  } catch (error) {
    console.error('Erreur suppression enseignant:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== FONCTIONS POUR ENSEIGNANT ====================

const getTeacherInfo = async (req, res) => {
  try {
    const { email } = req.params;
    const teacher = await User.findOne({ email: email.toLowerCase(), role: 'teacher' }).select('-password');
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    const className = teacher.assignedClasses && teacher.assignedClasses.length > 0 ? teacher.assignedClasses[0] : '';
    res.json({ success: true, className: className, subjects: teacher.subjects || [], teacherName: teacher.fullName, teacherId: teacher._id });
  } catch (error) {
    console.error('Erreur getTeacherInfo:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getStudentsByClass = async (req, res) => {
  try {
    const { className } = req.params;
    const students = await User.find({ role: 'student', className: className }).select('-password');
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('Erreur getStudentsByClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getAllStudents = async (req, res) => {
  try {
    const students = await User.find({ role: 'student' }).select('_id fullName email className parentCode linkedParents');
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('Erreur getAllStudents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const addStudentsToClass = async (req, res) => {
  try {
    const { className, studentIds } = req.body;
    let classObj = await Class.findOne({ name: className });
    if (!classObj) {
      classObj = await Class.create({
        name: className, level: className.split(' ')[0] || '', group: className.split(' ')[1] || '',
        teacherId: req.user._id, teacherName: req.user.fullName, capacity: 30, room: '', studentCount: 0, students: []
      });
    }
    let addedCount = 0;
    for (const studentId of studentIds) {
      const student = await User.findById(studentId);
      if (student && student.role === 'student') {
        student.className = className;
        await student.save();
        if (!classObj.students.includes(student._id)) {
          classObj.students.push(student._id);
          addedCount++;
        }
      }
    }
    classObj.studentCount = classObj.students.length;
    await classObj.save();
    res.json({ success: true, message: `${addedCount} élève(s) ajouté(s)`, addedCount });
  } catch (error) {
    console.error('Erreur addStudentsToClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const removeStudentFromClass = async (req, res) => {
  try {
    const { studentId, className } = req.body;
    const student = await User.findById(studentId);
    if (student && student.role === 'student') {
      student.className = '';
      await student.save();
    }
    const classObj = await Class.findOne({ name: className });
    if (classObj) {
      classObj.students = classObj.students.filter(id => id.toString() !== studentId);
      classObj.studentCount = classObj.students.length;
      await classObj.save();
    }
    res.json({ success: true, message: 'Élève retiré de la classe' });
  } catch (error) {
    console.error('Erreur removeStudentFromClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES LEÇONS ====================

const getLessons = async (req, res) => {
  try {
    const { className } = req.params;
    const lessons = await Lesson.find({ className: className }).sort('-createdAt');
    res.json({ success: true, lessons: lessons });
  } catch (error) {
    console.error('Erreur getLessons:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const addLesson = async (req, res) => {
  try {
    const { title, subject, description, type, className, deadline, files } = req.body;
    if (!title || !subject || !type || !className) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }
    const lesson = await Lesson.create({
      title, subject, description: description || '', type, className,
      deadline: deadline || null, files: files || [],
      teacherId: req.user._id, teacherName: req.user.fullName
    });
    res.status(201).json({ success: true, lesson: lesson });
  } catch (error) {
    console.error('Erreur addLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const updateLesson = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, subject, description, type, deadline, files } = req.body;

    console.log('📝 Modification ID:', id);

    if (!id) {
      return res.status(400).json({ success: false, message: 'ID manquant' });
    }

    const lesson = await Lesson.findById(id);
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Leçon non trouvée' });
    }

    const updatedLesson = await Lesson.findByIdAndUpdate(
      id,
      {
        title: title || lesson.title,
        subject: subject || lesson.subject,
        description: description !== undefined ? description : lesson.description,
        type: type || lesson.type,
        deadline: deadline !== undefined ? deadline : lesson.deadline,
        files: files || lesson.files,
      },
      { new: true }
    );

    res.json({ success: true, message: 'Leçon modifiée', lesson: updatedLesson });
  } catch (error) {
    console.error('Erreur updateLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const deleteLesson = async (req, res) => {
  try {
    const { id } = req.params;
    const lesson = await Lesson.findById(id);
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Leçon non trouvée' });
    }
    await lesson.deleteOne();
    res.json({ success: true, message: 'Leçon supprimée' });
  } catch (error) {
    console.error('Erreur deleteLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getAgenda = async (req, res) => {
  try {
    const { className } = req.params;
    const events = await Lesson.find({ className: className }).sort('createdAt');
    res.json({ success: true, schedule: events });
  } catch (error) {
    console.error('Erreur getAgenda:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const addGrade = async (req, res) => {
  try {
    const { studentId, subject, grade, appreciation } = req.body;
    const student = await User.findById(studentId);
    if (!student || student.role !== 'student') {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    if (!student.grades) student.grades = [];
    student.grades.push({ subject, grade, appreciation: appreciation || '', date: new Date(), teacherId: req.user._id, teacherName: req.user.fullName });
    await student.save();
    res.status(201).json({ success: true, message: 'Note ajoutée' });
  } catch (error) {
    console.error('Erreur addGrade:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const addAbsence = async (req, res) => {
  try {
    const { studentId, date, justified, reason } = req.body;
    const student = await User.findById(studentId);
    if (!student || student.role !== 'student') {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    if (!student.absences) student.absences = [];
    student.absences.push({ date: new Date(date), justified: justified || false, reason: reason || '', declaredBy: req.user.fullName });
    await student.save();
    res.status(201).json({ success: true, message: 'Absence enregistrée' });
  } catch (error) {
    console.error('Erreur addAbsence:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  createTeacher,
  getAllTeachers,
  getTeachersList,
  deleteTeacher,
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
};