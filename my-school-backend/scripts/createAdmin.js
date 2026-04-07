// scripts/createAdmin.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const path = require('path');

// Charger les variables d'environnement
dotenv.config({ path: path.join(__dirname, '../.env') });

// Importer le modèle User
const User = require('../src/models/User');

const createAdmin = async () => {
  try {
    // Connexion à MongoDB
    console.log('📦 Connexion à MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connecté à MongoDB');

    // Informations de l'admin
    const adminData = {
      fullName: 'Administrateur',
      email: 'admin@myschool.com',
      password: 'Admin1234', 
      role: 'admin',
      isVerified: true
    };

    console.log('\n=== CRÉATION ADMINISTRATEUR ===');
    console.log('📧 Email:', adminData.email);
    console.log('🔑 Mot de passe:', adminData.password);
    

    // Vérifier si l'admin existe déjà
    const existingAdmin = await User.findOne({ email: adminData.email });
    if (existingAdmin) {
      console.log('❌ Un administrateur avec cet email existe déjà');
      process.exit(1);
    }

    // Hasher le mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(adminData.password, salt);

    // Créer l'admin
    const admin = await User.create({
      ...adminData,
      password: hashedPassword
    });

    console.log('✅ Administrateur créé avec succès !');
    console.log('📧 Email:', admin.email);
    console.log('👤 Rôle:', admin.role);
    console.log('🆔 ID:', admin._id);

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
};

createAdmin();