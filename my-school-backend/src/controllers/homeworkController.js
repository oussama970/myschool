// backend/src/controllers/homeworkController.js
/// Contrôleur pour la gestion des soumissions de devoirs
/// Permet aux élèves de soumettre leurs devoirs et aux enseignants de les noter

const HomeworkSubmission = require('../models/HomeworkSubmission');
const Lesson = require('../models/Lesson');
const Student = require('../models/Student');

/// Élève soumet un devoir (création ou mise à jour)
const submitHomework = async (req, res) => {
  try {
    const { lessonId, content, attachments } = req.body;
    const studentId = req.user._id;
    const student = await Student.findById(studentId);
    
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return res.status(404).json({ success: false, message: 'Devoir non trouvé' });
    }
    
    // Vérifier si une soumission existe déjà
    let submission = await HomeworkSubmission.findOne({ lessonId, studentId });
    
    if (submission) {
      // Mise à jour de la soumission existante
      submission.content = content || '';
      submission.attachments = attachments || [];
      submission.submittedAt = new Date();
      submission.status = 'submitted';
      await submission.save();
    } else {
      // Nouvelle soumission
      submission = await HomeworkSubmission.create({
        lessonId,
        studentId,
        studentName: student.fullName,
        className: student.className || lesson.className,
        content: content || '',
        attachments: attachments || [],
        status: 'submitted'
      });
    }
    
    console.log(`✅ Devoir soumis par ${student.fullName} pour ${lesson.title}`);
    res.status(201).json({ success: true, submission });
  } catch (error) {
    console.error('❌ Erreur submitHomework:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Enseignant récupère toutes les soumissions pour un devoir spécifique
const getSubmissionsByLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    
    const submissions = await HomeworkSubmission.find({ lessonId })
      .sort({ submittedAt: -1 });
    
    console.log(`✅ ${submissions.length} soumissions pour le devoir ${lessonId}`);
    res.json({ success: true, submissions });
  } catch (error) {
    console.error('❌ Erreur getSubmissionsByLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Enseignant note une soumission de devoir
const gradeSubmission = async (req, res) => {
  try {
    const { submissionId } = req.params;
    const { grade, feedback } = req.body;
    
    const submission = await HomeworkSubmission.findById(submissionId);
    if (!submission) {
      return res.status(404).json({ success: false, message: 'Soumission non trouvée' });
    }
    
    submission.grade = grade;
    submission.feedback = feedback || '';
    submission.status = 'graded';
    submission.gradedAt = new Date();
    await submission.save();
    
    console.log(`✅ Soumission notée: ${grade}/20`);
    res.json({ success: true, submission });
  } catch (error) {
    console.error('❌ Erreur gradeSubmission:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Élève récupère toutes ses soumissions de devoirs
const getStudentSubmissions = async (req, res) => {
  try {
    const studentId = req.user._id;
    
    const submissions = await HomeworkSubmission.find({ studentId })
      .populate('lessonId', 'title subject deadline')
      .sort({ submittedAt: -1 });
    
    console.log(`✅ ${submissions.length} soumissions pour l'élève`);
    res.json({ success: true, submissions });
  } catch (error) {
    console.error('❌ Erreur getStudentSubmissions:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Élève récupère sa soumission pour un devoir spécifique
const getStudentSubmissionForLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const studentId = req.user._id;
    
    const submission = await HomeworkSubmission.findOne({ lessonId, studentId });
    
    res.json({ success: true, submission: submission || null });
  } catch (error) {
    console.error('❌ Erreur getStudentSubmissionForLesson:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  submitHomework,
  getSubmissionsByLesson,
  gradeSubmission,
  getStudentSubmissions,
  getStudentSubmissionForLesson
};