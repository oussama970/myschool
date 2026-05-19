const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '../.env' });

// Ancien modèle
const OldUser = require('../models/User');

// Nouveaux modèles
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Parent = require('../models/Parent');
const Admin = require('../models/Admin');

const migrate = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connecté à MongoDB');

    // Récupérer tous les anciens utilisateurs
    const oldUsers = await OldUser.find();
    console.log(`📚 ${oldUsers.length} utilisateurs à migrer`);

    for (const oldUser of oldUsers) {
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

      switch(oldUser.role) {
        case 'student':
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
          await Teacher.create(userData);
          console.log(`✅ Enseignant migré: ${oldUser.email}`);
          break;
          
        case 'parent':
          userData.linkedChildren = oldUser.linkedChildren || [];
          await Parent.create(userData);
          console.log(`✅ Parent migré: ${oldUser.email}`);
          break;
          
        case 'admin':
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

migrate();