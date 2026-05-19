const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const path = require('path');

// Charger les variables d'environnement
dotenv.config({ path: path.join(__dirname, '../.env') });

// Importer le modèle Admin (nouvelle architecture)
const Admin = require('../src/models/Admin');

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
      phoneNumber: '0612345678'
    };

    console.log('\n=== CRÉATION ADMINISTRATEUR ===');
    console.log('📧 Email:', adminData.email);
    console.log('🔑 Mot de passe:', adminData.password);

    // Vérifier si l'admin existe déjà dans la collection admins
    const existingAdmin = await Admin.findOne({ email: adminData.email });
    if (existingAdmin) {
      console.log('❌ Un administrateur avec cet email existe déjà');
      console.log('👤 Nom:', existingAdmin.fullName);
      console.log('📧 Email:', existingAdmin.email);
      process.exit(1);
    }

    // Hasher le mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(adminData.password, salt);

    // Créer l'admin
    const admin = await Admin.create({
      fullName: adminData.fullName,
      email: adminData.email,
      password: hashedPassword,
      phoneNumber: adminData.phoneNumber
    });

    console.log('\n✅ Administrateur créé avec succès !');
    console.log('📧 Email:', admin.email);
    console.log('👤 Nom:', admin.fullName);
    console.log('🆔 ID:', admin._id);
    console.log('\n🔐 Identifiants de connexion:');
    console.log('   Email: admin@myschool.com');
    console.log('   Mot de passe: Admin1234');

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
};

createAdmin();