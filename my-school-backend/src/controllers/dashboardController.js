// backend/src/controllers/dashboardController.js
/// Contrôleur pour le tableau de bord administrateur
/// Fournit les statistiques globales (enseignants, élèves, parents, classes) et les activités récentes

const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Parent = require('../models/Parent');
const Class = require('../models/Class');

/// Récupère les statistiques du tableau de bord
const getDashboardStats = async (req, res) => {
  try {
    // Compteurs principaux
    const totalTeachers = await Teacher.countDocuments();
    const totalParents = await Parent.countDocuments();
    const totalStudents = await Student.countDocuments();
    const totalClasses = await Class.countDocuments();
    const pendingTeachers = await Teacher.countDocuments({ isVerified: false });
    
    // Informations sur les classes
    const classes = await Class.find().select('name studentCount capacity');
    
    // Statistiques sur le nombre d'enfants par parent
    const parents = await Parent.find().populate('linkedChildren');
    let oneChild = 0, twoChildren = 0, threePlusChildren = 0;
    
    for (const parent of parents) {
      const childCount = parent.linkedChildren?.length || 0;
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
        parentsStats: { oneChild, twoChildren, threePlusChildren } 
      }
    });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les activités récentes (nouveaux enseignants, classes, parents, élèves)
const getRecentActivities = async (req, res) => {
  try {
    // Récupération des 5 derniers de chaque catégorie
    const recentTeachers = await Teacher.find().sort('-createdAt').limit(5).select('fullName email createdAt');
    const recentClasses = await Class.find().sort('-createdAt').limit(5).select('name level group createdAt');
    const recentParents = await Parent.find().sort('-createdAt').limit(5).select('fullName email createdAt');
    const recentStudents = await Student.find().sort('-createdAt').limit(5).select('fullName email className createdAt');
    
    const activities = [];
    
    // Formatage des activités
    for (const teacher of recentTeachers) {
      activities.push({ 
        id: teacher._id, 
        type: 'teacher', 
        title: 'Nouvel enseignant', 
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
        title: 'Nouvelle classe', 
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
        title: 'Nouveau parent', 
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
        title: 'Nouvel élève', 
        description: student.fullName, 
        className: student.className || 'Non assigné', 
        time: student.createdAt, 
        icon: 'school', 
        color: '#9C27B0' 
      });
    }
    
    // Tri par date décroissante
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));
    
    res.json({ 
      success: true, 
      activities: activities.slice(0, 10), 
      count: activities.length, 
      totalMessages: 0 
    });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getDashboardStats, getRecentActivities };