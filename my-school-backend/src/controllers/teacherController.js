// backend/src/controllers/teacherController.js
/// Contrôleur principal pour la gestion des enseignants (CRUD, leçons, notes, absences, événements, fichiers)
/// Point d'entrée unique pour toutes les fonctionnalités enseignants et parent/élève (lecture)

const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Class = require('../models/Class');
const Lesson = require('../models/Lesson');
const Event = require('../models/Event');
const bcrypt = require('bcryptjs');
const { sendTeacherCredentialsEmail } = require('../utils/emailService');
const upload = require('../middleware/upload');
const path = require('path');
const fs = require('fs');

// ==================== FONCTIONS POUR ADMIN (CRUD) ====================

/// Crée un nouvel enseignant (admin uniquement)
const createTeacher = async (req, res) => {
  try {
    const { fullName, email, password, phoneNumber, subjects, classes, sendEmail } = req.body;

    console.log('========== CRÉATION ENSEIGNANT ==========');
    console.log('📥 Données reçues:', { fullName, email, phoneNumber, subjects, classes });

    // Validation des champs requis
    if (!fullName || !email || !password) {
      return res.status(400).json({ 
        success: false,
        message: 'Nom complet, email et mot de passe sont requis' 
      });
    }

    // Validation de la longueur du mot de passe
    if (password.length < 8) {
      return res.status(400).json({ 
        success: false,
        message: 'Le mot de passe doit contenir au moins 8 caractères' 
      });
    }

    // Vérification de l'unicité de l'email
    const existingTeacher = await Teacher.findOne({ email: email.toLowerCase() });
    if (existingTeacher) {
      return res.status(400).json({ 
        success: false,
        message: 'Cet email est déjà utilisé' 
      });
    }

    // Hachage du mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Création de l'enseignant
    const teacher = await Teacher.create({
      fullName,
      email: email.toLowerCase(),
      password: hashedPassword,
      isVerified: true,
      phoneNumber: phoneNumber || '',
      subjects: subjects || [],
      assignedClasses: classes || []
    });

    console.log('✅ Enseignant créé avec succès');

    // Mise à jour des classes assignées
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

    // Envoi d'email de bienvenue (optionnel)
    if (sendEmail) {
      try {
        await sendTeacherCredentialsEmail(email, fullName, password);
        console.log('📧 Email envoyé avec succès');
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
    console.error('❌ Erreur création enseignant:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Récupère tous les enseignants (admin)
const getAllTeachers = async (req, res) => {
  try {
    const teachers = await Teacher.find()
      .select('-password')
      .sort('-createdAt');
    
    console.log(`📚 ${teachers.length} enseignants trouvés`);
    res.json({ success: true, teachers: teachers });
  } catch (error) {
    console.error('Erreur récupération enseignants:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère une liste simplifiée des noms d'enseignants (pour dropdown)
const getTeachersList = async (req, res) => {
  try {
    const teachers = await Teacher.find().select('fullName');
    const teacherNames = teachers.map(t => t.fullName);
    res.json({ success: true, teachers: teacherNames });
  } catch (error) {
    console.error('Erreur récupération liste enseignants:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime un enseignant (admin)
const deleteTeacher = async (req, res) => {
  try {
    const teacher = await Teacher.findById(req.params.id);
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    // Retirer l'enseignant des classes
    await Class.updateMany(
      { teacherId: teacher._id }, 
      { $set: { teacherId: null, teacherName: '' } }
    );
    
    await teacher.deleteOne();
    res.json({ success: true, message: 'Enseignant supprimé avec succès' });
  } catch (error) {
    console.error('Erreur suppression enseignant:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== FONCTIONS POUR ENSEIGNANT (INFO) ====================

/// Récupère les informations d'un enseignant par email
const getTeacherInfo = async (req, res) => {
  try {
    const { email } = req.params;
    const teacher = await Teacher.findOne({ email: email.toLowerCase() })
      .select('-password');
    
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    const assignedClasses = teacher.assignedClasses || [];
    
    res.json({ 
      success: true, 
      className: assignedClasses.length > 0 ? assignedClasses[0] : '',
      classes: assignedClasses,
      subjects: teacher.subjects || [], 
      teacherName: teacher.fullName, 
      teacherId: teacher._id,
      email: teacher.email,
      phoneNumber: teacher.phoneNumber || ''
    });
    
  } catch (error) {
    console.error('Erreur getTeacherInfo:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les classes assignées à un enseignant
const getTeacherClasses = async (req, res) => {
  try {
    let teacher;
    
    if (req.params.email) {
      teacher = await Teacher.findOne({ email: req.params.email.toLowerCase() });
    } 
    else if (req.user) {
      teacher = await Teacher.findById(req.user._id);
    }
    
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    const classes = teacher.assignedClasses || [];
    
    res.json({ success: true, classes: classes });
    
  } catch (error) {
    console.error('Erreur getTeacherClasses:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les notifications d'un enseignant (messages non lus, devoirs en attente)
const getTeacherNotifications = async (req, res) => {
  try {
    const { email } = req.params;
    const teacher = await Teacher.findOne({ email: email.toLowerCase() });
    
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    const unreadMessages = 0;
    const pendingWorks = await Lesson.countDocuments({
      teacherId: teacher._id,
      type: 'Devoir'
    });
    
    res.json({
      success: true,
      unreadMessages: unreadMessages,
      pendingWorks: pendingWorks
    });
  } catch (error) {
    console.error('Erreur getTeacherNotifications:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES ÉLÈVES ====================

/// Récupère les élèves d'une classe
const getStudentsByClass = async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET STUDENTS BY CLASS ==========');
    console.log('Classe:', decodedClassName);
    
    const students = await Student.find({ 
      className: decodedClassName 
    }).select('-password');
    
    console.log(`✅ ${students.length} élèves trouvés`);
    
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('❌ Erreur getStudentsByClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère tous les élèves (pour admin)
const getAllStudents = async (req, res) => {
  try {
    const students = await Student.find().select('-password');
    console.log(`📚 ${students.length} élèves trouvés au total`);
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('❌ Erreur getAllStudents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Ajoute des élèves à une classe
const addStudentsToClass = async (req, res) => {
  try {
    const { className, studentIds } = req.body;
    
    if (!className || !studentIds || !Array.isArray(studentIds)) {
      return res.status(400).json({ 
        success: false, 
        message: 'className et studentIds (tableau) sont requis' 
      });
    }
    
    console.log('========== ADD STUDENTS TO CLASS ==========');
    console.log('Classe:', className);
    
    let classObj = await Class.findOne({ name: className });
    if (!classObj) {
      classObj = await Class.create({
        name: className, 
        level: className.split(' ')[0] || '', 
        group: className.split(' ')[1] || '',
        teacherId: req.user._id, 
        teacherName: req.user.fullName, 
        capacity: 30, 
        room: '', 
        studentCount: 0, 
        students: []
      });
    }
    
    let addedCount = 0;
    
    for (const studentId of studentIds) {
      const student = await Student.findById(studentId);
      if (student) {
        if (student.className !== className) {
          student.className = className;
          await student.save();
          console.log(`✅ Élève ${student.fullName} mis à jour avec classe: ${className}`);
        }
        
        if (!classObj.students.includes(student._id)) {
          classObj.students.push(student._id);
          addedCount++;
        }
      }
    }
    
    classObj.studentCount = classObj.students.length;
    await classObj.save();
    
    res.json({ 
      success: true, 
      message: `${addedCount} élève(s) ajouté(s) à la classe ${className}`,
      addedCount
    });
  } catch (error) {
    console.error('❌ Erreur addStudentsToClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Retire un élève d'une classe
const removeStudentFromClass = async (req, res) => {
  try {
    const { studentId, className } = req.body;
    
    const student = await Student.findById(studentId);
    if (student) {
      student.className = '';
      await student.save();
      console.log(`✅ Élève ${student.fullName} retiré de la classe`);
    }
    
    const classObj = await Class.findOne({ name: className });
    if (classObj) {
      classObj.students = classObj.students.filter(id => id.toString() !== studentId);
      classObj.studentCount = classObj.students.length;
      await classObj.save();
    }
    
    res.json({ success: true, message: 'Élève retiré de la classe' });
  } catch (error) {
    console.error('❌ Erreur removeStudentFromClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES LEÇONS ====================

/// Récupère les leçons (cours, devoirs, rappels) d'une classe
const getLessons = async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET LESSONS ==========');
    console.log('Classe:', decodedClassName);
    console.log('Rôle utilisateur:', req.user?.role);
    console.log('Utilisateur ID:', req.user?._id);
    
    let filter = { className: decodedClassName };
    
    if (req.user && req.user.role === 'teacher') {
      filter.teacherId = req.user._id;
      console.log('👨‍🏫 Enseignant - Filtre par ID:', req.user._id);
    }
    
    const lessons = await Lesson.find(filter).sort({ createdAt: -1 });
    
    console.log(`✅ ${lessons.length} leçons trouvées`);
    lessons.forEach(l => {
      console.log(`   - [${l.type}] ${l.title} (${l.teacherName})`);
    });
    
    res.json({ success: true, lessons: lessons });
  } catch (error) {
    console.error('❌ Erreur getLessons:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Ajoute une nouvelle leçon (cours, devoir, rappel)
const addLesson = async (req, res) => {
  try {
    const { title, subject, description, type, className, deadline, files } = req.body;
    
    console.log('========== ADD LESSON ==========');
    console.log('Type:', type);
    console.log('Title:', title);
    console.log('ClassName:', className);
    console.log('Deadline reçue:', deadline);
    
    // Validation
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, message: 'Le titre est requis' });
    }
    
    if (!type || !['Cours', 'Devoir', 'Rappel'].includes(type)) {
      return res.status(400).json({ success: false, message: 'Type invalide' });
    }
    
    if (!className || className.trim() === '') {
      return res.status(400).json({ success: false, message: 'Le nom de la classe est requis' });
    }
    
    const teacher = await Teacher.findById(req.user._id);
    if (!teacher) {
      return res.status(403).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    // Gestion des fichiers
    let filesArray = [];
    if (files && typeof files === 'string') {
      try {
        filesArray = JSON.parse(files);
      } catch (e) {
        filesArray = [];
      }
    } else if (Array.isArray(files)) {
      filesArray = files;
    }
    
    // Gestion sécurisée de la date limite
    let deadlineDate = null;
    if (deadline && deadline !== null && deadline !== '') {
      try {
        if (typeof deadline === 'string' && deadline.includes('/')) {
          const parts = deadline.split('/');
          if (parts.length === 3) {
            deadlineDate = new Date(parts[2], parts[1] - 1, parts[0]);
            if (isNaN(deadlineDate.getTime())) {
              deadlineDate = null;
            }
          }
        } else if (typeof deadline === 'string' && !isNaN(Date.parse(deadline))) {
          deadlineDate = new Date(deadline);
        } else if (deadline instanceof Date) {
          deadlineDate = deadline;
        }
      } catch (e) {
        console.log('Erreur parsing deadline:', e);
        deadlineDate = null;
      }
    }
    
    const lesson = await Lesson.create({
      title: title.trim(),
      subject: subject || '',
      description: description || '',
      type,
      className,
      deadline: deadlineDate,
      files: filesArray,
      teacherId: req.user._id,
      teacherName: teacher.fullName
    });
    
    console.log('✅ Leçon ajoutée:', lesson._id);
    res.status(201).json({ success: true, lesson: lesson });
  } catch (error) {
    console.error('❌ Erreur addLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Met à jour une leçon existante
const updateLesson = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, subject, description, type, deadline, files } = req.body;

    console.log('========== UPDATE LESSON ==========');
    console.log('ID:', id);
    console.log('Type:', type);
    console.log('Deadline reçue:', deadline);

    const lesson = await Lesson.findById(id);
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Leçon non trouvée' });
    }
    
    if (lesson.teacherId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Vous n\'êtes pas autorisé à modifier cette leçon' 
      });
    }
    
    // Gestion des fichiers
    let filesArray = lesson.files;
    if (files !== undefined && files !== null) {
      if (typeof files === 'string') {
        try {
          filesArray = JSON.parse(files);
        } catch (e) {
          filesArray = lesson.files;
        }
      } else if (Array.isArray(files)) {
        filesArray = files;
      }
    }
    
    // Gestion sécurisée de la date limite
    let deadlineDate = lesson.deadline;
    if (deadline !== undefined && deadline !== null && deadline !== '') {
      try {
        if (typeof deadline === 'string' && deadline.includes('/')) {
          const parts = deadline.split('/');
          if (parts.length === 3) {
            deadlineDate = new Date(parts[2], parts[1] - 1, parts[0]);
            if (isNaN(deadlineDate.getTime())) {
              deadlineDate = null;
            }
          } else {
            deadlineDate = null;
          }
        } else if (typeof deadline === 'string' && !isNaN(Date.parse(deadline))) {
          deadlineDate = new Date(deadline);
        } else if (deadline instanceof Date) {
          deadlineDate = deadline;
        } else {
          deadlineDate = null;
        }
      } catch (e) {
        console.log('Erreur parsing deadline:', e);
        deadlineDate = null;
      }
    }

    const updatedLesson = await Lesson.findByIdAndUpdate(
      id,
      {
        title: title || lesson.title,
        subject: subject !== undefined ? subject : lesson.subject,
        description: description !== undefined ? description : lesson.description,
        type: type || lesson.type,
        deadline: deadlineDate,
        files: filesArray,
      },
      { new: true }
    );

    console.log('✅ Leçon modifiée:', updatedLesson._id);
    res.json({ success: true, message: 'Leçon modifiée', lesson: updatedLesson });
  } catch (error) {
    console.error('❌ Erreur updateLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Supprime une leçon
const deleteLesson = async (req, res) => {
  try {
    const { id } = req.params;
    const lesson = await Lesson.findById(id);
    
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Leçon non trouvée' });
    }
    
    if (lesson.teacherId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Vous n\'êtes pas autorisé à supprimer cette leçon' 
      });
    }
    
    await lesson.deleteOne();
    res.json({ success: true, message: 'Leçon supprimée' });
  } catch (error) {
    console.error('Erreur deleteLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère l'agenda (calendrier) d'une classe
const getAgenda = async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    const events = await Lesson.find({ className: decodedClassName }).sort('createdAt');
    res.json({ success: true, schedule: events });
  } catch (error) {
    console.error('Erreur getAgenda:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES FICHIERS ====================

/// Upload d'un fichier
const uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Aucun fichier uploadé' });
    }
    
    const fileInfo = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      fileType: path.extname(req.file.originalname).toLowerCase(),
      fileSize: req.file.size,
      filePath: req.file.path
    };
    
    console.log('✅ Fichier uploadé:', fileInfo.originalName);
    res.json({ success: true, file: fileInfo });
  } catch (error) {
    console.error('❌ Erreur upload:', error);
    res.status(500).json({ success: false, message: 'Erreur upload' });
  }
};

/// Téléchargement d'un fichier
const downloadFile = async (req, res) => {
  try {
    const { filename } = req.params;
    const filePath = path.join(__dirname, '../../uploads', filename);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ success: false, message: 'Fichier non trouvé' });
    }
    
    res.download(filePath);
  } catch (error) {
    console.error('❌ Erreur download:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== NOTES ET ABSENCES (ÉCRITURE) ====================

/// Ajoute une note pour un élève
const addGrade = async (req, res) => {
  try {
    const { studentId, subject, grade, appreciation } = req.body;
    
    if (!studentId || !subject) {
      return res.status(400).json({ success: false, message: 'studentId et subject sont requis' });
    }
    
    if (grade === undefined || grade < 0 || grade > 20) {
      return res.status(400).json({ success: false, message: 'La note doit être comprise entre 0 et 20' });
    }
    
    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    if (!student.grades) student.grades = [];
    student.grades.push({ 
      subject, 
      grade: parseFloat(grade), 
      appreciation: appreciation || '', 
      date: new Date(), 
      teacherId: req.user._id, 
      teacherName: req.user.fullName 
    });
    
    await student.save();
    res.status(201).json({ success: true, message: 'Note ajoutée' });
  } catch (error) {
    console.error('Erreur addGrade:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Ajoute une absence pour un élève
const addAbsence = async (req, res) => {
  try {
    const { studentId, date, justified, reason, subject } = req.body;
    
    if (!studentId) {
      return res.status(400).json({ success: false, message: 'studentId est requis' });
    }
    
    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    let absenceDate = new Date();
    if (date) {
      absenceDate = new Date(date);
    }
    
    const timeStr = absenceDate.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
    
    if (!student.absences) student.absences = [];
    student.absences.push({ 
      date: absenceDate,
      time: timeStr,
      subject: subject || 'Non spécifié',
      justified: justified === true, 
      reason: reason || '', 
      declaredBy: req.user.fullName,
      teacherId: req.user._id
    });
    
    await student.save();
    res.status(201).json({ success: true, message: 'Absence enregistrée' });
  } catch (error) {
    console.error('Erreur addAbsence:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== NOTES ET ABSENCES (LECTURE) ====================

/// Récupère les notes d'un élève
const getStudentGrades = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('grades fullName');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const formattedGrades = (student.grades || []).map(grade => ({
      _id: grade._id,
      subject: grade.subject,
      grade: grade.grade,
      appreciation: grade.appreciation || '',
      date: grade.date,
      teacherName: grade.teacherName || 'Enseignant'
    }));
    
    res.json({ success: true, grades: formattedGrades });
  } catch (error) {
    console.error('❌ Erreur getStudentGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les absences d'un élève
const getStudentAbsences = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('absences fullName');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const formattedAbsences = (student.absences || []).map(absence => ({
      _id: absence._id,
      date: absence.date,
      time: absence.time || '',
      subject: absence.subject || '',
      justified: absence.justified || false,
      reason: absence.reason || '',
      declaredBy: absence.declaredBy || 'Enseignant'
    }));
    
    res.json({ success: true, absences: formattedAbsences });
  } catch (error) {
    console.error('❌ Erreur getStudentAbsences:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère à la fois les notes et les absences d'un élève
const getStudentGradesAndAbsences = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('grades absences fullName');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const formattedGrades = (student.grades || []).map(grade => ({
      _id: grade._id,
      subject: grade.subject,
      grade: grade.grade,
      appreciation: grade.appreciation || '',
      date: grade.date,
      teacherName: grade.teacherName || 'Enseignant'
    }));
    
    const formattedAbsences = (student.absences || []).map(absence => ({
      _id: absence._id,
      date: absence.date,
      time: absence.time || '',
      subject: absence.subject || '',
      justified: absence.justified || false,
      reason: absence.reason || '',
      declaredBy: absence.declaredBy || 'Enseignant'
    }));
    
    res.json({ 
      success: true, 
      grades: formattedGrades,
      absences: formattedAbsences
    });
  } catch (error) {
    console.error('❌ Erreur getStudentGradesAndAbsences:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== NOTES ET ABSENCES (SUPPRESSION) ====================

/// Supprime une note d'un élève
const deleteGrade = async (req, res) => {
  try {
    const { id } = req.params;
    
    const student = await Student.findOne({ 'grades._id': id });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Note non trouvée' });
    }
    
    const grade = student.grades.id(id);
    if (!grade) {
      return res.status(404).json({ success: false, message: 'Note non trouvée' });
    }
    
    if (grade.teacherId && grade.teacherId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Vous n\'êtes pas autorisé à supprimer cette note' 
      });
    }
    
    grade.deleteOne();
    await student.save();
    
    res.json({ success: true, message: 'Note supprimée avec succès' });
  } catch (error) {
    console.error('❌ Erreur deleteGrade:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime une absence d'un élève
const deleteAbsence = async (req, res) => {
  try {
    const { id } = req.params;
    
    const student = await Student.findOne({ 'absences._id': id });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Absence non trouvée' });
    }
    
    const absence = student.absences.id(id);
    if (!absence) {
      return res.status(404).json({ success: false, message: 'Absence non trouvée' });
    }
    
    if (absence.teacherId && absence.teacherId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Vous n\'êtes pas autorisé à supprimer cette absence' 
      });
    }
    
    absence.deleteOne();
    await student.save();
    
    res.json({ success: true, message: 'Absence supprimée avec succès' });
  } catch (error) {
    console.error('❌ Erreur deleteAbsence:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DU PROFIL ENSEIGNANT ====================

/// Met à jour le profil de l'enseignant (nom, téléphone)
const updateTeacherProfile = async (req, res) => {
  try {
    const { email, fullName, phoneNumber } = req.body;
    
    console.log('========== UPDATE TEACHER PROFILE ==========');
    console.log('Email:', email);
    
    const teacher = await Teacher.findOne({ email: email.toLowerCase() });
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    if (fullName && fullName.trim() !== '') {
      teacher.fullName = fullName.trim();
    }
    
    if (phoneNumber !== undefined) {
      teacher.phoneNumber = phoneNumber;
    }
    
    await teacher.save();
    
    res.json({ 
      success: true, 
      message: 'Profil mis à jour avec succès',
      teacher: {
        fullName: teacher.fullName,
        email: teacher.email,
        phoneNumber: teacher.phoneNumber
      }
    });
  } catch (error) {
    console.error('❌ Erreur updateTeacherProfile:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Change le mot de passe de l'enseignant
const changeTeacherPassword = async (req, res) => {
  try {
    const { email, currentPassword, newPassword } = req.body;
    
    console.log('========== CHANGE TEACHER PASSWORD ==========');
    console.log('Email:', email);
    
    const teacher = await Teacher.findOne({ email: email.toLowerCase() });
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    const isMatch = await bcrypt.compare(currentPassword, teacher.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Mot de passe actuel incorrect' });
    }
    
    if (newPassword.length < 8) {
      return res.status(400).json({ success: false, message: 'Le nouveau mot de passe doit contenir au moins 8 caractères' });
    }
    
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    teacher.password = hashedPassword;
    
    await teacher.save();
    
    res.json({ success: true, message: 'Mot de passe modifié avec succès' });
  } catch (error) {
    console.error('❌ Erreur changeTeacherPassword:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== ROUTES POUR PARENT/ÉLÈVE (LECTURE SEULEMENT) ====================

/// Récupère les détails d'un élève (pour parent)
const getStudentDetails = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('-password');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    res.json({ success: true, student: student });
  } catch (error) {
    console.error('❌ Erreur getStudentDetails:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les notes d'un élève (pour parent)
const getStudentGradesForParent = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('grades fullName');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const formattedGrades = (student.grades || []).map(grade => ({
      subject: grade.subject,
      grade: grade.grade,
      appreciation: grade.appreciation || '',
      date: grade.date,
      teacherName: grade.teacherName || ''
    }));
    
    res.json({ success: true, grades: formattedGrades });
  } catch (error) {
    console.error('❌ Erreur getStudentGradesForParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les absences d'un élève (pour parent)
const getStudentAbsencesForParent = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await Student.findById(studentId).select('absences fullName');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const formattedAbsences = (student.absences || []).map(absence => ({
      date: absence.date,
      time: absence.time || '',
      subject: absence.subject || '',
      justified: absence.justified || false,
      reason: absence.reason || '',
      declaredBy: absence.declaredBy || ''
    }));
    
    console.log('📊 Absences formatées pour parent:', formattedAbsences.length);
    res.json({ success: true, absences: formattedAbsences });
  } catch (error) {
    console.error('❌ Erreur getStudentAbsencesForParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES ÉVÉNEMENTS (PARENT ET ENSEIGNANT) ====================

/// Ajoute un événement (enseignant)
const addEvent = async (req, res) => {
  try {
    const { 
      title, 
      description, 
      date, 
      teacherId, 
      teacherName, 
      className, 
      status, 
      responseDeadline 
    } = req.body;
    
    console.log('========== ADD EVENT ==========');
    console.log('Titre:', title);
    console.log('Classe:', className);
    console.log('Date:', date);
    console.log('Date limite réponse:', responseDeadline);
    
    const students = await Student.find({ className: className });
    console.log(`📚 ${students.length} élèves trouvés dans la classe`);
    
    const studentResponses = students.map(student => ({
      studentId: student._id,
      studentName: student.fullName,
      response: 'pending',
      comment: ''
    }));
    
    const event = await Event.create({
      title,
      description,
      date: new Date(date),
      teacherId,
      teacherName,
      className,
      status: status || 'pending',
      responseDeadline: responseDeadline ? new Date(responseDeadline) : null,
      studentResponses
    });
    
    console.log(`✅ Événement créé: ${event._id}`);
    
    res.status(201).json({ success: true, event: event });
  } catch (error) {
    console.error('❌ Erreur addEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Récupère les événements d'une classe (enseignant)
const getEvents = async (req, res) => {
  try {
    const { className } = req.params;
    const { teacherId } = req.query;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET EVENTS ==========');
    console.log('Classe:', decodedClassName);
    console.log('Teacher ID:', teacherId);
    
    let query = { className: decodedClassName };
    if (teacherId) {
      query.teacherId = teacherId;
    }
    
    const events = await Event.find(query).sort({ date: -1 });
    
    console.log(`✅ ${events.length} événements trouvés`);
    res.json({ success: true, events: events });
  } catch (error) {
    console.error('❌ Erreur getEvents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime un événement (enseignant)
const deleteEvent = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('========== DELETE EVENT ==========');
    console.log('Event ID:', id);
    
    const event = await Event.findById(id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Événement non trouvé' });
    }
    
    await event.deleteOne();
    console.log('✅ Événement supprimé');
    
    res.json({ success: true, message: 'Événement supprimé' });
  } catch (error) {
    console.error('❌ Erreur deleteEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Répond à un événement (parent)
const respondToEvent = async (req, res) => {
  try {
    const { eventId, studentId, studentName, response, comment } = req.body;
    
    console.log('========== RESPOND TO EVENT ==========');
    console.log('Event ID:', eventId);
    console.log('Student:', studentName);
    console.log('Response:', response);
    
    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Événement non trouvé' });
    }
    
    // Vérification de la date limite
    if (event.responseDeadline && new Date() > new Date(event.responseDeadline)) {
      return res.status(400).json({ 
        success: false, 
        message: 'La date limite de réponse est dépassée' 
      });
    }
    
    const existingResponseIndex = event.studentResponses.findIndex(
      r => r.studentId.toString() === studentId
    );
    
    if (existingResponseIndex !== -1) {
      event.studentResponses[existingResponseIndex].response = response;
      if (comment) event.studentResponses[existingResponseIndex].comment = comment;
      event.studentResponses[existingResponseIndex].respondedAt = new Date();
    } else {
      event.studentResponses.push({
        studentId,
        studentName,
        response,
        comment: comment || '',
        respondedAt: new Date()
      });
    }
    
    await event.save();
    console.log(`✅ Réponse enregistrée pour ${studentName}`);
    
    res.json({ success: true, event: event });
  } catch (error) {
    console.error('❌ Erreur respondToEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les événements pour un parent (avec la réponse de l'élève)
const getEventsForParent = async (req, res) => {
  try {
    const { studentId } = req.params;
    
    console.log('========== GET EVENTS FOR PARENT ==========');
    console.log('Student ID:', studentId);
    
    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const events = await Event.find({ className: student.className })
      .sort({ date: -1 });
    
    const eventsWithResponse = events.map(event => {
      const studentResponse = event.studentResponses.find(
        r => r.studentId.toString() === studentId
      );
      
      return {
        ...event.toObject(),
        myResponse: studentResponse ? studentResponse.response : 'pending',
        myComment: studentResponse ? studentResponse.comment : '',
        respondedAt: studentResponse ? studentResponse.respondedAt : null
      };
    });
    
    console.log(`✅ ${eventsWithResponse.length} événements trouvés`);
    res.json({ success: true, events: eventsWithResponse });
  } catch (error) {
    console.error('❌ Erreur getEventsForParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== EXPORTATIONS ====================

module.exports = {
  // Admin functions
  createTeacher,
  getAllTeachers,
  getTeachersList,
  deleteTeacher,
  
  // Teacher info functions
  getTeacherInfo,
  getTeacherClasses,
  getTeacherNotifications,
  
  // Student management
  getStudentsByClass,
  getAllStudents,
  addStudentsToClass,
  removeStudentFromClass,
  
  // Lesson management
  getLessons,
  addLesson,
  updateLesson,
  deleteLesson,
  getAgenda,
  
  // File management
  uploadFile,
  downloadFile,
  
  // Grades and absences (write)
  addGrade,
  addAbsence,
  
  // Grades and absences (read)
  getStudentGrades,
  getStudentAbsences,
  getStudentGradesAndAbsences,
  
  // Grades and absences (delete)
  deleteGrade,
  deleteAbsence,
  
  // Profile management
  updateTeacherProfile,
  changeTeacherPassword,
  
  // Parent/Student read only
  getStudentDetails,
  getStudentGradesForParent,
  getStudentAbsencesForParent,
  
  // Event management
  addEvent,
  getEvents,
  deleteEvent,
  respondToEvent,
  getEventsForParent
};