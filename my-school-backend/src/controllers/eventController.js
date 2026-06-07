// backend/src/controllers/eventController.js
/// Contrôleur pour la gestion des événements (sorties, réunions, etc.)
/// Permet de créer, lire, supprimer des événements et de gérer les réponses des parents/élèves

const Event = require('../models/Event');
const Student = require('../models/Student');

/// Récupère les événements d'une classe (pour l'enseignant)
const getEventsByClass = async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET EVENTS BY CLASS ==========');
    console.log('Classe:', decodedClassName);
    
    const events = await Event.find({ className: decodedClassName })
      .sort({ date: -1 });
    
    console.log(`✅ ${events.length} événements trouvés`);
    res.json({ success: true, events: events });
  } catch (error) {
    console.error('❌ Erreur getEventsByClass:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Crée un nouvel événement (avec date limite de réponse optionnelle)
const createEvent = async (req, res) => {
  try {
    const { 
      title, 
      description, 
      date, 
      teacherId, 
      teacherName, 
      className, 
      status,
      responseDeadline  // ✅ AJOUT: date limite de réponse
    } = req.body;
    
    console.log('========== CREATE EVENT ==========');
    console.log('Titre:', title);
    console.log('Classe:', className);
    console.log('Teacher ID:', teacherId);
    console.log('Date limite réponse:', responseDeadline);
    
    // Validation des champs requis
    if (!title || !description || !date || !teacherId || !className) {
      return res.status(400).json({ 
        success: false, 
        message: 'Champs requis: title, description, date, teacherId, className' 
      });
    }
    
    // Récupérer tous les élèves de la classe
    const students = await Student.find({ className: className });
    console.log(`📚 ${students.length} élèves trouvés dans la classe`);
    
    // Initialiser les réponses des élèves à "pending"
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
      responseDeadline: responseDeadline ? new Date(responseDeadline) : null, // ✅ AJOUT
      studentResponses
    });
    
    console.log(`✅ Événement créé: ${event._id}`);
    
    res.status(201).json({ success: true, event: event });
  } catch (error) {
    console.error('❌ Erreur createEvent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Supprime un événement
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

/// Parent répond à un événement (avec vérification de la date limite)
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
    
    // ✅ Vérifier si la date limite de réponse est dépassée
    if (event.responseDeadline && new Date() > new Date(event.responseDeadline)) {
      return res.status(400).json({ 
        success: false, 
        message: 'La date limite de réponse est dépassée. Vous ne pouvez plus répondre.' 
      });
    }
    
    // Mettre à jour ou ajouter la réponse de l'élève
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

/// Récupère les événements pour un parent (avec la date limite)
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
    
    // Ajouter la réponse de l'élève à chaque événement
    const eventsWithResponse = events.map(event => {
      const studentResponse = event.studentResponses.find(
        r => r.studentId.toString() === studentId
      );
      
      return {
        ...event.toObject(),
        myResponse: studentResponse ? studentResponse.response : 'pending',
        myComment: studentResponse ? studentResponse.comment : '',
        respondedAt: studentResponse ? studentResponse.respondedAt : null,
        responseDeadline: event.responseDeadline // ✅ AJOUT: inclure la date limite
      };
    });
    
    console.log(`✅ ${eventsWithResponse.length} événements trouvés`);
    res.json({ success: true, events: eventsWithResponse });
  } catch (error) {
    console.error('❌ Erreur getEventsForParent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  getEventsByClass,
  createEvent,
  deleteEvent,
  respondToEvent,
  getEventsForParent
};