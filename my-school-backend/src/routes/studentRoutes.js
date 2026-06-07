const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const Student = require('../models/Student');
const Lesson = require('../models/Lesson');
const Schedule = require('../models/Schedule');
const Event = require('../models/Event');
const ExamGrade = require('../models/ExamGrade');
const Message = require('../models/Message');
const bcrypt = require('bcryptjs');

// ==================== IMPORT HOMEWORK CONTROLLER ====================
const {
  submitHomework,
  getStudentSubmissions,
  getStudentSubmissionForLesson
} = require('../controllers/homeworkController');

// Toutes les routes nécessitent une authentification
router.use(protect);

// ==================== INFORMATIONS ÉLÈVE ====================

// Récupérer les informations d'un élève
router.get('/info/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const student = await Student.findOne({ email: email.toLowerCase() }).select('-password');
    
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    res.json({
      success: true,
      _id: student._id,
      fullName: student.fullName,
      email: student.email,
      className: student.className,
      parentCode: student.parentCode,
      isVerified: student.isVerified
    });
  } catch (error) {
    console.error('Erreur getStudentInfo:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== COURS, DEVOIRS, RAPPELS ====================

// Récupérer les cours/devoirs/rappels d'un élève (par classe)
router.get('/lessons/:className', async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET STUDENT LESSONS ==========');
    console.log('Classe:', decodedClassName);
    console.log('Élève ID:', req.user._id);
    
    // Récupérer TOUS les cours de la classe (pas de filtre enseignant)
    const lessons = await Lesson.find({ className: decodedClassName })
      .sort({ createdAt: -1 });
    
    console.log(`✅ ${lessons.length} leçons trouvées`);
    res.json({ success: true, lessons: lessons });
  } catch (error) {
    console.error('❌ Erreur getStudentLessons:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== EMPLOI DU TEMPS ====================

// Récupérer l'emploi du temps d'un élève (par classe)
router.get('/schedule/:className', async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET STUDENT SCHEDULE ==========');
    console.log('Classe:', decodedClassName);
    
    const schedule = await Schedule.findOne({ className: decodedClassName });
    
    if (schedule) {
      console.log('✅ Emploi du temps trouvé');
      res.json({ success: true, schedule: schedule.schedule });
    } else {
      console.log('⚠️ Aucun emploi du temps trouvé');
      res.json({ success: true, schedule: {} });
    }
  } catch (error) {
    console.error('❌ Erreur getStudentSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== NOTES D'EXAMEN ====================

// Récupérer les notes d'examen d'un élève
router.get('/exam-grades/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    console.log('========== GET STUDENT EXAM GRADES ==========');
    console.log('Élève ID:', studentId);
    
    const grades = await ExamGrade.find({ studentId })
      .populate('examId', 'type day timeSlot date subject')
      .sort({ createdAt: -1 });
    
    console.log(`✅ ${grades.length} notes d'examen trouvées`);
    res.json({ success: true, grades: grades });
  } catch (error) {
    console.error('❌ Erreur getStudentExamGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== ABSENCES ====================

// Récupérer les absences d'un élève
router.get('/absences/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    console.log('========== GET STUDENT ABSENCES ==========');
    console.log('Élève ID:', studentId);
    
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
      declaredBy: absence.declaredBy || 'Enseignant'
    }));
    
    console.log(`✅ ${formattedAbsences.length} absences trouvées`);
    res.json({ success: true, absences: formattedAbsences });
  } catch (error) {
    console.error('❌ Erreur getStudentAbsences:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== ÉVÉNEMENTS ====================

// Récupérer les événements pour un élève
router.get('/events/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    console.log('========== GET STUDENT EVENTS ==========');
    console.log('Élève ID:', studentId);
    
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
        respondedAt: studentResponse ? studentResponse.respondedAt : null,
        responseDeadline: event.responseDeadline
      };
    });
    
    console.log(`✅ ${eventsWithResponse.length} événements trouvés`);
    res.json({ success: true, events: eventsWithResponse });
  } catch (error) {
    console.error('❌ Erreur getStudentEvents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Élève répond à un événement
router.post('/events/respond', async (req, res) => {
  try {
    const { eventId, studentId, studentName, response, comment } = req.body;
    
    console.log('========== STUDENT RESPOND TO EVENT ==========');
    console.log('Event ID:', eventId);
    console.log('Student:', studentName);
    console.log('Response:', response);
    
    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Événement non trouvé' });
    }
    
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
    console.error('❌ Erreur studentRespondToEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== MESSAGES ====================

// Récupérer les conversations d'un élève
router.get('/conversations/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    console.log('========== GET STUDENT CONVERSATIONS ==========');
    console.log('Student ID:', studentId);
    
    const messages = await Message.find({
      $or: [
        { senderId: studentId },
        { receiverId: studentId }
      ]
    }).sort({ createdAt: -1 });
    
    const conversationsMap = new Map();
    
    for (const msg of messages) {
      const isSender = msg.senderId.toString() === studentId;
      const contactId = isSender ? msg.receiverId.toString() : msg.senderId.toString();
      const contactName = isSender ? msg.receiverName : msg.senderName;
      const contactRole = isSender ? msg.receiverRole : msg.senderRole;
      
      if (!conversationsMap.has(contactId)) {
        conversationsMap.set(contactId, {
          id: contactId,
          name: contactName,
          role: contactRole,
          lastMessage: msg.message,
          lastMessageTime: msg.createdAt,
          unreadCount: (!isSender && !msg.isRead) ? 1 : 0
        });
      } else if (!isSender && !msg.isRead) {
        const conv = conversationsMap.get(contactId);
        conv.unreadCount += 1;
      }
    }
    
    const conversations = Array.from(conversationsMap.values());
    console.log(`✅ ${conversations.length} conversations trouvées`);
    res.json({ success: true, conversations: conversations });
  } catch (error) {
    console.error('❌ Erreur getStudentConversations:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Envoyer un message depuis un élève
router.post('/send-message', async (req, res) => {
  try {
    const { receiverId, receiverName, receiverRole, message, attachments } = req.body;
    const studentId = req.user._id;
    const studentName = req.user.fullName;
    
    console.log('========== SEND STUDENT MESSAGE ==========');
    console.log('To:', receiverName);
    console.log('Message:', message?.substring(0, 50));
    
    const newMessage = await Message.create({
      senderId: studentId,
      senderName: studentName,
      senderRole: 'student',
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: receiverRole,
      message: message,
      attachments: attachments || [],
      isRead: false
    });
    
    console.log('✅ Message envoyé');
    res.status(201).json({ success: true, message: newMessage });
  } catch (error) {
    console.error('❌ Erreur sendStudentMessage:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== PROFIL ====================

// Mettre à jour le profil d'un élève
router.put('/profile', async (req, res) => {
  try {
    const { email, fullName, phoneNumber } = req.body;
    
    console.log('========== UPDATE STUDENT PROFILE ==========');
    console.log('Email:', email);
    
    const student = await Student.findOne({ email: email.toLowerCase() });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    if (fullName && fullName.trim() !== '') {
      student.fullName = fullName.trim();
    }
    
    if (phoneNumber !== undefined) {
      student.phoneNumber = phoneNumber;
    }
    
    await student.save();
    
    res.json({ 
      success: true, 
      message: 'Profil mis à jour avec succès',
      student: {
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber
      }
    });
  } catch (error) {
    console.error('❌ Erreur updateStudentProfile:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Changer le mot de passe d'un élève
router.post('/change-password', async (req, res) => {
  try {
    const { email, currentPassword, newPassword } = req.body;
    
    console.log('========== CHANGE STUDENT PASSWORD ==========');
    console.log('Email:', email);
    
    const student = await Student.findOne({ email: email.toLowerCase() });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const isMatch = await bcrypt.compare(currentPassword, student.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Mot de passe actuel incorrect' });
    }
    
    if (newPassword.length < 8) {
      return res.status(400).json({ success: false, message: 'Le nouveau mot de passe doit contenir au moins 8 caractères' });
    }
    
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    student.password = hashedPassword;
    
    await student.save();
    
    res.json({ success: true, message: 'Mot de passe modifié avec succès' });
  } catch (error) {
    console.error('❌ Erreur changeStudentPassword:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ==================== NOUVELLES ROUTES: SOUMISSIONS DEVOIRS ====================

// Soumettre un devoir (texte + fichiers)
router.post('/submit-homework', async (req, res) => {
  try {
    const { lessonId, content, attachments } = req.body;
    const studentId = req.user._id;
    
    console.log('========== SUBMIT HOMEWORK ==========');
    console.log('Lesson ID:', lessonId);
    console.log('Student ID:', studentId);
    console.log('Content length:', content?.length || 0);
    console.log('Attachments:', attachments?.length || 0);
    
    // Vérifier que le devoir existe
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Devoir non trouvé' });
    }
    
    // Vérifier que c'est bien un devoir
    if (lesson.type !== 'Devoir') {
      return res.status(400).json({ success: false, message: 'Seuls les devoirs peuvent être soumis' });
    }
    
    // Récupérer les infos de l'élève
    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    // Importer le modèle HomeworkSubmission
    const HomeworkSubmission = require('../models/HomeworkSubmission');
    
    // Chercher une soumission existante
    let submission = await HomeworkSubmission.findOne({ lessonId, studentId });
    
    if (submission) {
      // Mettre à jour la soumission existante
      submission.content = content || '';
      submission.attachments = attachments || [];
      submission.submittedAt = new Date();
      submission.status = 'submitted';
      await submission.save();
      console.log(`✅ Devoir mis à jour pour ${student.fullName}`);
    } else {
      // Créer une nouvelle soumission
      submission = await HomeworkSubmission.create({
        lessonId,
        studentId,
        studentName: student.fullName,
        className: student.className || lesson.className,
        content: content || '',
        attachments: attachments || [],
        status: 'submitted'
      });
      console.log(`✅ Nouveau devoir soumis par ${student.fullName}`);
    }
    
    res.status(201).json({ success: true, submission });
  } catch (error) {
    console.error('❌ Erreur submitHomework:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
});

// Récupérer toutes les soumissions de l'élève connecté
router.get('/my-submissions', async (req, res) => {
  try {
    const studentId = req.user._id;
    
    console.log('========== GET MY SUBMISSIONS ==========');
    console.log('Student ID:', studentId);
    
    const HomeworkSubmission = require('../models/HomeworkSubmission');
    
    const submissions = await HomeworkSubmission.find({ studentId })
      .populate('lessonId', 'title subject deadline')
      .sort({ submittedAt: -1 });
    
    console.log(`✅ ${submissions.length} soumissions trouvées`);
    res.json({ success: true, submissions });
  } catch (error) {
    console.error('❌ Erreur getMySubmissions:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Récupérer la soumission d'un élève pour un devoir spécifique
router.get('/homework-submission/:lessonId', async (req, res) => {
  try {
    const { lessonId } = req.params;
    const studentId = req.user._id;
    
    console.log('========== GET STUDENT SUBMISSION FOR LESSON ==========');
    console.log('Lesson ID:', lessonId);
    console.log('Student ID:', studentId);
    
    const HomeworkSubmission = require('../models/HomeworkSubmission');
    
    const submission = await HomeworkSubmission.findOne({ lessonId, studentId });
    
    res.json({ success: true, submission: submission || null });
  } catch (error) {
    console.error('❌ Erreur getStudentSubmissionForLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;