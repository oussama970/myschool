// scripts/migrate.js
/// Script de migration des données de l'ancien modèle User vers les nouveaux modèles spécifiques
/// Permet de séparer les utilisateurs par rôle (Student, Teacher, Parent, Admin)

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '../.env' });

// Ancien modèle (User unique)
const OldUser = require('../models/User');

// Nouveaux modèles (séparés par rôle)
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Parent = require('../models/Parent');
const Admin = require('../models/Admin');

/// Fonction principale de migration
const migrate = async () => {
  try {
    // Connexion à la base de données
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connecté à MongoDB');

    // Récupérer tous les anciens utilisateurs
    const oldUsers = await OldUser.find();
    console.log(`📚 ${oldUsers.length} utilisateurs à migrer`);

    // Parcourir chaque utilisateur et le migrer vers le bon modèle
    for (const oldUser of oldUsers) {
      // Données communes à tous les utilisateurs
      const userData = {
        fullName: oldUser.fullName,
        email: oldUser.email,
        password: oldUser.password,
        isVerified: oldUser.isVerified,
        phoneNumber: oldUser.phoneNumber || '',
        subjects: oldUser.subjects || [],
        assignedClasses: oldUser.assignedClasses || [],
        createdAt: oldUser.createdAt
      };

      // Migration selon le rôle
      switch(oldUser.role) {
        case 'student':
          // Données spécifiques aux étudiants
          userData.childCode = oldUser.childCode;
          userData.parentCode = oldUser.parentCode;
          userData.className = oldUser.className;
          userData.linkedParents = oldUser.linkedParents || [];
          userData.grades = oldUser.grades || [];
          userData.absences = oldUser.absences || [];
          await Student.create(userData);
          console.log(`✅ Étudiant migré: ${oldUser.email}`);
          break;
          
        case 'teacher':
          // Données spécifiques aux enseignants
          await Teacher.create(userData);
          console.log(`✅ Enseignant migré: ${oldUser.email}`);
          break;
          
        case 'parent':
          // Données spécifiques aux parents
          userData.linkedChildren = oldUser.linkedChildren || [];
          await Parent.create(userData);
          console.log(`✅ Parent migré: ${oldUser.email}`);
          break;
          
        case 'admin':
          // Données spécifiques aux administrateurs
          await Admin.create(userData);
          console.log(`✅ Admin migré: ${oldUser.email}`);
          break;
      }
    }

    console.log('🎉 Migration terminée !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
};

// Exécution du script de migration
migrate();