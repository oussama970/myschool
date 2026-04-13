const Class = require('../models/Class');
const User = require('../models/User');

// @desc    Créer une classe
// @route   POST /api/admin/classes
// @access  Private/Admin
const createClass = async (req, res) => {
  try {
    const { level, group, name, teacher, capacity, room } = req.body;
    
    if (!level || !group || !name) {
      return res.status(400).json({ 
        success: false, 
        message: 'Champs requis manquants: level, group, name' 
      });
    }
    
    const existingClass = await Class.findOne({ name: name });
    if (existingClass) {
      return res.status(400).json({ 
        success: false, 
        message: 'Cette classe existe déjà' 
      });
    }
    
    let teacherUser = null;
    if (teacher && teacher.trim() !== '') {
      teacherUser = await User.findOne({ fullName: teacher, role: 'teacher' });
    }
    
    const newClass = await Class.create({
      name: name,
      level: level,
      group: group,
      teacherId: teacherUser ? teacherUser._id : null,
      teacherName: teacherUser ? teacherUser.fullName : 'Non assigné',
      capacity: capacity || 30,
      room: room || '',
      studentCount: 0,
      parentCount: 0,
      students: []
    });
    
    if (teacherUser) {
      teacherUser.assignedClasses = teacherUser.assignedClasses || [];
      if (!teacherUser.assignedClasses.includes(name)) {
        teacherUser.assignedClasses.push(name);
        await teacherUser.save();
      }
    }
    
    res.status(201).json({ 
      success: true, 
      message: 'Classe créée avec succès',
      class: newClass 
    });
    
  } catch (error) {
    console.error('Erreur création classe:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur serveur: ' + error.message 
    });
  }
};

// @desc    Récupérer toutes les classes
// @route   GET /api/admin/classes
// @access  Private/Admin
const getAllClasses = async (req, res) => {
  try {
    const classes = await Class.find().sort({ level: 1, group: 1 });
    res.json({ success: true, classes });
  } catch (error) {
    console.error('Erreur récupération classes:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Récupérer la liste des noms de classes
// @route   GET /api/admin/classes/list
// @access  Private/Admin
const getClassesList = async (req, res) => {
  try {
    const classes = await Class.find().select('name');
    const classNames = classes.map(c => c.name);
    res.json({ success: true, classes: classNames });
  } catch (error) {
    console.error('Erreur récupération liste classes:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Supprimer une classe
// @route   DELETE /api/admin/classes/:id
// @access  Private/Admin
const deleteClass = async (req, res) => {
  try {
    const classToDelete = await Class.findById(req.params.id);
    if (!classToDelete) {
      return res.status(404).json({ success: false, message: 'Classe non trouvée' });
    }
    await User.updateMany(
      { assignedClasses: classToDelete.name }, 
      { $pull: { assignedClasses: classToDelete.name } }
    );
    await classToDelete.deleteOne();
    res.json({ success: true, message: 'Classe supprimée' });
  } catch (error) {
    console.error('Erreur suppression classe:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { createClass, getAllClasses, getClassesList, deleteClass };