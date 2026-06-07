// config/database.js
/// Configuration de la connexion à la base de données MongoDB
/// Établit la connexion avec l'URI stockée dans les variables d'environnement

const mongoose = require('mongoose');

/// Établit la connexion à la base de données MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connecté');
  } catch (error) {
    console.error('❌ Erreur MongoDB:', error);
    process.exit(1);
  }
};

module.exports = connectDB;