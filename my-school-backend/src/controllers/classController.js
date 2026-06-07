// backend/src/controllers/classController.js
/// Contrôleur pour la gestion des classes (CRUD)
/// Permet de créer, lire, supprimer des classes et de gérer l'assignation des enseignants

const Class = require('../models/Class');
const Teacher = require('../models/Teacher');

/// Crée une nouvelle classe et l'assigne à un enseignant
const createClass = async (req, res) => {
  try {
    const { level, group, name, teacher, capacity, room } = req.body;
    
    // Validation des champs requis
    if (!level || !group || !name) {
      return res.status(400).json({ success: false, message: 'Champs requis: level, group, name' });
    }
    
    // Vérification de l'existence de la classe
    const existingClass = await Class.findOne({ name });
    if (existingClass) {
      return res.status(400).json({ success: false, message: 'Cette classe existe déjà' });
    }
    
    // Recherche de l'enseignant assigné
    let teacherUser = null;
    if (teacher && teacher.trim() !== '') {
      teacherUser = await Teacher.findOne({ fullName: teacher });
    }
    
    // Création de la classe
    const newClass = await Class.create({
      name, level, group,
      teacherId: teacherUser ? teacherUser._id : null,
      teacherName: teacherUser ? teacherUser.fullName : 'Non assigné',
      capacity: capacity || 30,
      room: room || '',
      studentCount: 0,
      students: []
    });
    
    // Ajout de la classe à la liste des classes de l'enseignant
    if (teacherUser) {
      teacherUser.assignedClasses = teacherUser.assignedClasses || [];
      if (!teacherUser.assignedClasses.includes(name)) {
        teacherUser.assignedClasses.push(name);
        await teacherUser.save();
      }
    }
    
    res.status(201).json({ success: true, message: 'Classe créée', class: newClass });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

/// Récupère toutes les classes (avec tous les détails)
const getAllClasses = async (req, res) => {
  try {
    const classes = await Class.find().sort({ level: 1, group: 1 });
    res.json({ success: true, classes });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère une liste simplifiée des noms de classes (pour dropdowns)
const getClassesList = async (req, res) => {
  try {
    const classes = await Class.find().select('name');
    const classNames = classes.map(c => c.name);
    res.json({ success: true, classes: classNames });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime une classe et retire son nom des enseignants assignés
const deleteClass = async (req, res) => {
  try {
    const classToDelete = await Class.findById(req.params.id);
    if (!classToDelete) {
      return res.status(404).json({ success: false, message: 'Classe non trouvée' });
    }
    
    // Retirer la classe de la liste des enseignants assignés
    await Teacher.updateMany(
      { assignedClasses: classToDelete.name },
      { $pull: { assignedClasses: classToDelete.name } }
    );
    
    await classToDelete.deleteOne();
    res.json({ success: true, message: 'Classe supprimée' });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { createClass, getAllClasses, getClassesList, deleteClass };