const User = require('../models/User');
const Class = require('../models/Class');

// @desc    Récupérer les statistiques du tableau de bord
// @route   GET /api/admin/dashboard/stats
// @access  Private/Admin
const getDashboardStats = async (req, res) => {
  try {
    const totalTeachers = await User.countDocuments({ role: 'teacher' });
    const totalParents = await User.countDocuments({ role: 'parent' });
    const totalStudents = await User.countDocuments({ role: 'student' });
    const totalClasses = await Class.countDocuments();
    const pendingTeachers = await User.countDocuments({ role: 'teacher', isVerified: false });
    const classes = await Class.find().select('name studentCount capacity');
    
    // Statistiques des parents par nombre d'enfants
    const parents = await User.find({ role: 'parent' }).select('children linkedParents');
    let oneChild = 0;
    let twoChildren = 0;
    let threePlusChildren = 0;
    
    for (const parent of parents) {
      const childCount = (parent.children?.length || 0) + (parent.linkedParents?.length || 0);
      if (childCount === 1) oneChild++;
      else if (childCount === 2) twoChildren++;
      else if (childCount >= 3) threePlusChildren++;
    }
    
    res.json({
      success: true,
      stats: {
        totalTeachers,
        totalParents,
        totalStudents,
        totalClasses,
        pendingTeachers,
        classes,
        parentsStats: {
          oneChild,
          twoChildren,
          threePlusChildren
        }
      }
    });
  } catch (error) {
    console.error('Erreur récupération statistiques:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Récupérer les activités récentes
// @route   GET /api/admin/recent-activities
// @access  Private/Admin
const getRecentActivities = async (req, res) => {
  try {
    // Récupérer les 5 derniers enseignants
    const recentTeachers = await User.find({ role: 'teacher' })
      .sort('-createdAt')
      .limit(5)
      .select('fullName email createdAt');
    
    // Récupérer les 5 dernières classes
    const recentClasses = await Class.find()
      .sort('-createdAt')
      .limit(5)
      .select('name level group createdAt');
    
    // Récupérer les 5 derniers parents
    const recentParents = await User.find({ role: 'parent' })
      .sort('-createdAt')
      .limit(5)
      .select('fullName email createdAt');
    
    // Récupérer les 5 derniers élèves
    const recentStudents = await User.find({ role: 'student' })
      .sort('-createdAt')
      .limit(5)
      .select('fullName email className createdAt');
    
    // Formater les activités
    const activities = [];
    
    for (const teacher of recentTeachers) {
      activities.push({
        id: teacher._id,
        type: 'teacher',
        title: 'Nouvel enseignant inscrit',
        description: teacher.fullName,
        email: teacher.email,
        time: teacher.createdAt,
        icon: 'person_add',
        color: '#0288D1'
      });
    }
    
    for (const classItem of recentClasses) {
      activities.push({
        id: classItem._id,
        type: 'class',
        title: 'Nouvelle classe créée',
        description: classItem.name,
        time: classItem.createdAt,
        icon: 'add_box',
        color: '#4CAF9F'
      });
    }
    
    for (const parent of recentParents) {
      activities.push({
        id: parent._id,
        type: 'parent',
        title: 'Nouveau parent inscrit',
        description: parent.fullName,
        email: parent.email,
        time: parent.createdAt,
        icon: 'family_restroom',
        color: '#FF9800'
      });
    }
    
    for (const student of recentStudents) {
      activities.push({
        id: student._id,
        type: 'student',
        title: 'Nouvel élève inscrit',
        description: student.fullName,
        className: student.className || 'Non assigné',
        time: student.createdAt,
        icon: 'school',
        color: '#9C27B0'
      });
    }
    
    // Trier par date décroissante
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));
    
    // Compter les messages non lus (à adapter selon votre système de messagerie)
    const totalMessages = 0;
    
    res.json({
      success: true,
      activities: activities.slice(0, 10),
      count: activities.length,
      totalMessages: totalMessages
    });
  } catch (error) {
    console.error('Erreur getRecentActivities:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getDashboardStats, getRecentActivities };