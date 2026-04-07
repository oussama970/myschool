const User = require('../models/User');

const getAllStudents = async (req, res) => {
  try {
    const students = await User.find({ role: 'student' }).select('-password').sort('-createdAt');
    res.json({ success: true, students });
  } catch (error) {
    console.error('Erreur récupération élèves:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const deleteStudent = async (req, res) => {
  try {
    const student = await User.findById(req.params.id);
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Élève non trouvé' });
    }
    await student.deleteOne();
    res.json({ success: true, message: 'Élève supprimé' });
  } catch (error) {
    console.error('Erreur suppression élève:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getAllStudents, deleteStudent };