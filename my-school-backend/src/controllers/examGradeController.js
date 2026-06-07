// backend/src/controllers/examGradeController.js
/// Contrôleur pour la gestion des notes d'examens
/// Permet d'ajouter, modifier et récupérer les notes des élèves pour les examens/évaluations

const ExamGrade = require('../models/ExamGrade');
const AgendaEvent = require('../models/AgendaEvent');

/// Ajoute ou met à jour une note d'examen pour un élève
const addExamGrade = async (req, res) => {
  try {
    const { examId, studentId, studentName, subject, grade, appreciation, photoUrl } = req.body;

    console.log('========== ADD EXAM GRADE ==========');
    console.log('Examen ID:', examId);
    console.log('Élève:', studentName);
    console.log('Note:', grade);

    // Vérifier si l'examen existe
    const exam = await AgendaEvent.findById(examId);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Examen non trouvé' });
    }

    // Vérifier si une note existe déjà pour cet élève et cet examen
    let examGrade = await ExamGrade.findOne({ examId, studentId });

    if (examGrade) {
      // Mettre à jour la note existante
      examGrade.grade = grade;
      examGrade.appreciation = appreciation;
      if (photoUrl) examGrade.photoUrl = photoUrl;
      await examGrade.save();
      console.log('✅ Note mise à jour');
    } else {
      // Créer une nouvelle note
      examGrade = await ExamGrade.create({
        examId,
        studentId,
        studentName,
        subject,
        grade,
        appreciation,
        photoUrl,
        teacherId: req.user._id,
        teacherName: req.user.fullName
      });
      console.log('✅ Nouvelle note créée');
    }

    res.status(201).json({ success: true, grade: examGrade });
  } catch (error) {
    console.error('❌ Erreur addExamGrade:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Récupère toutes les notes d'un examen (pour l'enseignant)
const getExamGrades = async (req, res) => {
  try {
    const { examId } = req.params;

    console.log('========== GET EXAM GRADES ==========');
    console.log('Examen ID:', examId);

    const grades = await ExamGrade.find({ examId })
      .populate('examId', 'type day timeSlot date subject')
      .sort({ studentName: 1 });

    console.log(`✅ ${grades.length} notes trouvées`);
    res.json({ success: true, grades });
  } catch (error) {
    console.error('❌ Erreur getExamGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère toutes les notes d'un élève (pour l'élève ou le parent)
const getStudentExamGrades = async (req, res) => {
  try {
    const { studentId } = req.params;

    console.log('========== GET STUDENT EXAM GRADES ==========');
    console.log('Élève ID:', studentId);

    const grades = await ExamGrade.find({ studentId })
      .populate('examId', 'type day timeSlot date subject')
      .sort({ createdAt: -1 });

    console.log(`✅ ${grades.length} notes trouvées pour l'élève`);
    
    // Afficher les types pour déboguer
    grades.forEach(grade => {
      const examType = grade.examId?.type || grade.type || 'Non défini';
      console.log(`   - ${grade.subject}: ${examType} - Note: ${grade.grade}`);
    });

    res.json({ success: true, grades });
  } catch (error) {
    console.error('❌ Erreur getStudentExamGrades:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { addExamGrade, getExamGrades, getStudentExamGrades };