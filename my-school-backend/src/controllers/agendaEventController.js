// backend/src/controllers/agendaEventController.js
/// Contrôleur pour la gestion des événements agenda (examens, évaluations)
/// Permet de créer, lire, supprimer des événements et de récupérer les notes associées

const AgendaEvent = require('../models/AgendaEvent');
const ExamGrade = require('../models/ExamGrade'); // ✅ AJOUTER CET IMPORT

/// Récupère tous les événements d'une classe pour un enseignant spécifique
const getEventsByClass = async (req, res) => {
  try {
    const { className } = req.params;
    const { teacherId } = req.query;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET AGENDA EVENTS ==========');
    console.log('Classe:', decodedClassName);
    console.log('Teacher ID:', teacherId);
    
    let query = { className: decodedClassName };
    
    if (teacherId && teacherId.trim() !== '') {
      query.teacherId = teacherId;
    }
    
    const events = await AgendaEvent.find(query).sort({ date: 1 });
    
    console.log(`✅ ${events.length} événements trouvés`);
    res.json({ success: true, events: events });
  } catch (error) {
    console.error('❌ Erreur getEventsByClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Ajoute un nouvel événement agenda (examen, évaluation orale, etc.)
const addEvent = async (req, res) => {
  try {
    const { className, subject, type, day, timeSlot, date, teacherId, teacherName } = req.body;
    
    console.log('========== ADD AGENDA EVENT ==========');
    console.log('Classe:', className);
    console.log('Type:', type);
    console.log('Jour:', day);
    console.log('Horaire:', timeSlot);
    console.log('Date:', date);
    
    // Validation des champs requis
    if (!className || !subject || !type || !day || !timeSlot || !date) {
      return res.status(400).json({ success: false, message: 'Tous les champs sont requis' });
    }
    
    // Validation du type d'événement
    const validTypes = ['Orale', 'Evaluation', 'Examen'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ 
        success: false, 
        message: `Type invalide. Types acceptés: ${validTypes.join(', ')}` 
      });
    }
    
    const finalTeacherId = teacherId || req.user._id;
    const finalTeacherName = teacherName || req.user.fullName;
    
    const newEvent = await AgendaEvent.create({
      className,
      subject,
      type,
      day,
      timeSlot,
      date: new Date(date),
      teacherId: finalTeacherId,
      teacherName: finalTeacherName
    });
    
    console.log('✅ Événement ajouté:', newEvent._id);
    
    res.status(201).json({ success: true, event: newEvent });
  } catch (error) {
    console.error('❌ Erreur addEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Supprime un événement agenda (vérification de l'autorisation)
const deleteEvent = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('========== DELETE AGENDA EVENT ==========');
    console.log('ID:', id);
    
    const event = await AgendaEvent.findById(id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Événement non trouvé' });
    }
    
    // Vérification que l'utilisateur est autorisé à supprimer l'événement
    if (event.teacherId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Non autorisé' });
    }
    
    await event.deleteOne();
    console.log('✅ Événement supprimé');
    res.json({ success: true, message: 'Événement supprimé' });
  } catch (error) {
    console.error('❌ Erreur deleteEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère tous les examens d'une classe avec les notes d'un élève spécifique
const getAllExamsByClass = async (req, res) => {
  try {
    const { className } = req.params;
    const { studentId } = req.query;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET ALL EXAMS BY CLASS ==========');
    console.log('Classe:', decodedClassName);
    console.log('Student ID:', studentId);
    
    // Récupérer TOUS les examens de la classe
    const events = await AgendaEvent.find({ className: decodedClassName }).sort({ date: -1 });
    
    // Récupérer les notes de l'élève (s'il est fourni)
    let gradesMap = {};
    if (studentId) {
      const grades = await ExamGrade.find({ studentId: studentId });
      for (let grade of grades) {
        gradesMap[grade.examId.toString()] = {
          grade: grade.grade,
          appreciation: grade.appreciation || '',
          photoUrl: grade.photoUrl || '',
          teacherName: grade.teacherName || '',
          hasGrade: true
        };
      }
    }
    
    // Ajouter les notes aux examens
    const eventsWithGrades = events.map(event => {
      const eventId = event._id.toString();
      const gradeData = gradesMap[eventId] || null;
      
      return {
        _id: event._id,
        type: event.type,
        subject: event.subject,
        day: event.day,
        timeSlot: event.timeSlot,
        date: event.date,
        description: event.description || '',
        teacherId: event.teacherId,
        teacherName: event.teacherName,
        hasGrade: gradeData !== null,
        grade: gradeData?.grade || null,
        appreciation: gradeData?.appreciation || '',
        photoUrl: gradeData?.photoUrl || '',
        gradeTeacherName: gradeData?.teacherName || ''
      };
    });
    
    console.log(`✅ ${eventsWithGrades.length} examens trouvés pour la classe`);
    res.json({ success: true, events: eventsWithGrades });
  } catch (error) {
    console.error('❌ Erreur getAllExamsByClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getEventsByClass, addEvent, deleteEvent, getAllExamsByClass };