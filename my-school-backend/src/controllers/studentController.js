const User = require('../models/User');

// @desc    Récupérer tous les élèves
// @route   GET /api/admin/students
// @access  Private/Admin
const getAllStudents = async (req, res) => {
  try {
    const students = await User.find({ role: 'student' }).select('-password');
    console.log(`📚 ${students.length} élèves trouvés`);
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('Erreur récupération élèves:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Supprimer un élève
// @route   DELETE /api/admin/students/:id
// @access  Private/Admin
const deleteStudent = async (req, res) => {
  try {
    const student = await User.findById(req.params.id);
    if (!student || student.role !== 'student') {
      return res.status(404).json({ success: false, message: 'Élève non trouvé' });
    }
    await student.deleteOne();
    res.json({ success: true, message: 'Élève supprimé' });
  } catch (error) {
    console.error('Erreur suppression élève:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getAllStudents, deleteStudent };