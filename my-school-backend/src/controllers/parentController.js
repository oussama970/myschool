// backend/src/controllers/parentController.js
/// Contrôleur pour la gestion des parents et de leurs enfants
/// Gère la liaison parent-enfant, la consultation des notes, absences, événements,
/// cours, devoirs, enseignants et messagerie parent-enseignant

const Parent = require('../models/Parent');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Lesson = require('../models/Lesson');
const Event = require('../models/Event');
const ExamGrade = require('../models/ExamGrade');
const Message = require('../models/Message');

// ==================== GESTION DES PARENTS (ADMIN) ====================

/// Récupère tous les parents avec leurs enfants liés
const getAllParents = async (req, res) => {
  try {
    const parents = await Parent.find().select('-password');
    
    const parentsWithChildren = await Promise.all(parents.map(async (parent) => {
      let children = [];
      if (parent.linkedChildren && parent.linkedChildren.length > 0) {
        children = await Student.find({ '_id': { $in: parent.linkedChildren } }).select('fullName email className childCode');
      }
      const parentObj = parent.toObject();
      parentObj.children = children;
      return parentObj;
    }));
    
    res.json({ success: true, parents: parentsWithChildren });
  } catch (error) {
    console.error('Erreur getAllParents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime un parent et retire son email des enfants liés
const deleteParent = async (req, res) => {
  try {
    const parent = await Parent.findById(req.params.id);
    if (!parent) {
      return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    }
    
    // Retirer le parent des listes linkedParents des étudiants
    await Student.updateMany(
      { linkedParents: parent.email },
      { $pull: { linkedParents: parent.email } }
    );
    
    await parent.deleteOne();
    res.json({ success: true, message: 'Parent supprimé' });
  } catch (error) {
    console.error('Erreur deleteParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== GESTION DES ENFANTS (PARENT) ====================

/// Récupère tous les enfants d'un parent par son email
const getParentChildren = async (req, res) => {
  try {
    const { email } = req.params;
    const emailLower = email.toLowerCase();
    
    console.log('========== GET PARENT CHILDREN ==========');
    console.log('Parent email:', emailLower);
    
    const parent = await Parent.findOne({ email: emailLower });
    if (!parent) {
      return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    }
    
    const children = await Student.find({ 
      '_id': { $in: parent.linkedChildren } 
    }).select('fullName email className childCode');
    
    console.log(`✅ ${children.length} enfants trouvés`);
    res.json({ success: true, children: children });
  } catch (error) {
    console.error('❌ Erreur getParentChildren:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Lie un enfant à un parent via le code parent
const linkChildToParent = async (req, res) => {
  try {
    const { parentCode, parentId } = req.body;
    
    console.log('========== LINK CHILD TO PARENT ==========');
    console.log('ParentCode:', parentCode);
    
    const child = await Student.findOne({ parentCode: parentCode });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Code invalide' });
    }
    
    const parent = await Parent.findById(parentId);
    if (!parent) {
      return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    }
    
    if (parent.linkedChildren.includes(child._id)) {
      return res.status(400).json({ success: false, message: 'Cet enfant est déjà lié' });
    }
    
    parent.linkedChildren.push(child._id);
    await parent.save();
    
    if (!child.linkedParents.includes(parent.email)) {
      child.linkedParents.push(parent.email);
      await child.save();
    }
    
    console.log(`✅ Enfant ${child.fullName} lié au parent ${parent.fullName}`);
    res.json({ success: true, message: 'Enfant lié avec succès', child: child });
  } catch (error) {
    console.error('❌ Erreur linkChildToParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== COURS ET DEVOIRS ====================

/// Récupère les cours, devoirs et rappels pour un enfant (via sa classe)
const getChildLessons = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD LESSONS ==========');
    console.log('Child ID:', childId);
    
    const child = await Student.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const lessons = await Lesson.find({ className: child.className })
      .sort({ createdAt: -1 });
    
    console.log(`✅ ${lessons.length} leçons trouvées pour la classe ${child.className}`);
    res.json({ success: true, lessons: lessons });
  } catch (error) {
    console.error('❌ Erreur getChildLessons:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== NOTES ====================

/// Récupère les notes classiques d'un enfant (stockées dans Student.grades)
const getChildGrades = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD GRADES ==========');
    console.log('Child ID:', childId);
    
    const child = await Student.findById(childId).select('grades fullName');
    if (!child) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const grades = (child.grades || []).map(grade => ({
      subject: grade.subject,
      grade: grade.grade,
      appreciation: grade.appreciation,
      date: grade.date,
      teacherName: grade.teacherName
    }));
    
    console.log(`✅ ${grades.length} notes trouvées`);
    res.json({ success: true, grades: grades });
  } catch (error) {
    console.error('❌ Erreur getChildGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les notes d'examen d'un enfant (modèle ExamGrade)
const getChildExamGrades = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD EXAM GRADES ==========');
    console.log('Child ID:', childId);
    
    const examGrades = await ExamGrade.find({ studentId: childId })
      .sort({ createdAt: -1 });
    
    console.log(`✅ ${examGrades.length} notes d'examen trouvées`);
    res.json({ success: true, grades: examGrades });
  } catch (error) {
    console.error('❌ Erreur getChildExamGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== ABSENCES ====================

/// Récupère les absences d'un enfant
const getChildAbsences = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD ABSENCES ==========');
    console.log('Child ID:', childId);
    
    const child = await Student.findById(childId).select('absences fullName');
    if (!child) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const absences = (child.absences || []).map(absence => ({
      date: absence.date,
      subject: absence.subject,
      justified: absence.justified,
      reason: absence.reason,
      declaredBy: absence.declaredBy
    }));
    
    console.log(`✅ ${absences.length} absences trouvées`);
    res.json({ success: true, absences: absences });
  } catch (error) {
    console.error('❌ Erreur getChildAbsences:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== ÉVÉNEMENTS ====================

/// Récupère les événements pour un enfant (avec la réponse du parent)
const getChildEvents = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD EVENTS ==========');
    console.log('Child ID:', childId);
    
    const child = await Student.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const events = await Event.find({ className: child.className })
      .sort({ date: -1 });
    
    const eventsWithResponse = events.map(event => {
      const studentResponse = event.studentResponses.find(
        r => r.studentId.toString() === childId
      );
      
      return {
        _id: event._id,
        title: event.title,
        description: event.description,
        date: event.date,
        status: event.status,
        teacherName: event.teacherName,
        myResponse: studentResponse ? studentResponse.response : 'pending',
        myComment: studentResponse ? studentResponse.comment : '',
        respondedAt: studentResponse ? studentResponse.respondedAt : null
      };
    });
    
    console.log(`✅ ${eventsWithResponse.length} événements trouvés`);
    res.json({ success: true, events: eventsWithResponse });
  } catch (error) {
    console.error('❌ Erreur getChildEvents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Parent répond à un événement
const parentRespondToEvent = async (req, res) => {
  try {
    const { eventId, studentId, studentName, response, comment } = req.body;
    
    console.log('========== PARENT RESPOND TO EVENT ==========');
    console.log('Event ID:', eventId);
    console.log('Student:', studentName);
    console.log('Response:', response);
    
    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Événement non trouvé' });
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
    console.error('❌ Erreur parentRespondToEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== ENSEIGNANTS ====================

/// Récupère les enseignants de la classe d'un enfant
const getChildTeachers = async (req, res) => {
  try {
    const { childId } = req.params;
    
    console.log('========== GET CHILD TEACHERS ==========');
    console.log('Child ID:', childId);
    
    const child = await Student.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const teachers = await Teacher.find({ 
      assignedClasses: child.className 
    }).select('-password');
    
    console.log(`✅ ${teachers.length} enseignants trouvés pour la classe ${child.className}`);
    res.json({ success: true, teachers: teachers });
  } catch (error) {
    console.error('❌ Erreur getChildTeachers:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== MESSAGES ====================

/// Récupère les conversations d'un parent avec les enseignants
const getParentConversations = async (req, res) => {
  try {
    const { parentId } = req.params;
    
    console.log('========== GET PARENT CONVERSATIONS ==========');
    console.log('Parent ID:', parentId);
    
    const messages = await Message.find({
      $or: [
        { senderId: parentId },
        { receiverId: parentId }
      ]
    }).sort({ createdAt: -1 });
    
    const conversationsMap = new Map();
    
    for (const msg of messages) {
      const isSender = msg.senderId.toString() === parentId;
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
    console.error('❌ Erreur getParentConversations:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Envoie un message depuis un parent
const sendParentMessage = async (req, res) => {
  try {
    const { receiverId, receiverName, receiverRole, message, attachments } = req.body;
    const parentId = req.user._id;
    const parentName = req.user.fullName;
    
    console.log('========== SEND PARENT MESSAGE ==========');
    console.log('To:', receiverName);
    console.log('Message:', message);
    
    const newMessage = await Message.create({
      senderId: parentId,
      senderName: parentName,
      senderRole: 'parent',
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
    console.error('❌ Erreur sendParentMessage:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  // Admin functions
  getAllParents,
  deleteParent,
  // Parent functions
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
};