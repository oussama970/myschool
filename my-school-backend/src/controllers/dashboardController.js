const User = require('../models/User');
const Class = require('../models/Class');

const getDashboardStats = async (req, res) => {
  try {
    const totalTeachers = await User.countDocuments({ role: 'teacher' });
    const totalParents = await User.countDocuments({ role: 'parent' });
    const totalStudents = await User.countDocuments({ role: 'student' });
    const totalClasses = await Class.countDocuments();
    const pendingTeachers = await User.countDocuments({ role: 'teacher', isVerified: false });
    const classes = await Class.find().select('name studentCount');
    res.json({
      success: true,
      stats: { totalTeachers, totalParents, totalStudents, totalClasses, pendingTeachers, classes }
    });
  } catch (error) {
    console.error('Erreur récupération statistiques:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getDashboardStats };