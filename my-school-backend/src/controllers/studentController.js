// backend/src/controllers/studentController.js
/// Contrôleur pour la gestion des étudiants (administration)
/// Permet de récupérer tous les étudiants et d'en supprimer

const Student = require('../models/Student');

/// Récupère la liste complète de tous les étudiants
const getAllStudents = async (req, res) => {
  try {
    const students = await Student.find().select('-password');
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Supprime un étudiant par son ID
const deleteStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    await student.deleteOne();
    res.json({ success: true, message: 'Élève supprimé' });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getAllStudents, deleteStudent };