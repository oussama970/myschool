const Student = require('../models/Student');

const getAllStudents = async (req, res) => {
  try {
    const students = await Student.find().select('-password');
    res.json({ success: true, students: students });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

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