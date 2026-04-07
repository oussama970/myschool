const Class = require('../models/Class');
const User = require('../models/User');

const createClass = async (req, res) => {
  try {
    const { level, group, className, teacher, capacity, room } = req.body;
    const existingClass = await Class.findOne({ name: className });
    if (existingClass) {
      return res.status(400).json({ message: 'Cette classe existe déjà' });
    }
    const teacherUser = await User.findOne({ fullName: teacher, role: 'teacher' });
    if (!teacherUser) {
      return res.status(400).json({ message: 'Enseignant non trouvé' });
    }
    const newClass = await Class.create({
      name: className, level, group, teacherId: teacherUser._id, teacherName: teacher,
      capacity: capacity || 30, room: room || '', studentCount: 0, parentCount: 0, students: []
    });
    teacherUser.assignedClasses = teacherUser.assignedClasses || [];
    teacherUser.assignedClasses.push(className);
    await teacherUser.save();
    res.status(201).json({ success: true, message: 'Classe créée', class: newClass });
  } catch (error) {
    console.error('Erreur création classe:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getAllClasses = async (req, res) => {
  try {
    const classes = await Class.find().sort({ level: 1, group: 1 });
    res.json({ success: true, classes });
  } catch (error) {
    console.error('Erreur récupération classes:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const getClassesList = async (req, res) => {
  try {
    const classes = await Class.find().select('name');
    const classNames = classes.map(c => c.name);
    res.json({ success: true, classes: classNames });
  } catch (error) {
    console.error('Erreur récupération liste classes:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const deleteClass = async (req, res) => {
  try {
    const classToDelete = await Class.findById(req.params.id);
    if (!classToDelete) {
      return res.status(404).json({ message: 'Classe non trouvée' });
    }
    await User.updateMany({ className: classToDelete.name }, { $set: { className: '' } });
    await classToDelete.deleteOne();
    res.json({ success: true, message: 'Classe supprimée' });
  } catch (error) {
    console.error('Erreur suppression classe:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { createClass, getAllClasses, getClassesList, deleteClass };