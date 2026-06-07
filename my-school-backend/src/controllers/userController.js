// backend/src/controllers/userController.js
/// Contrôleur pour la gestion des utilisateurs (profil et enfants liés)
/// Permet de récupérer le profil d'un parent et ses enfants liés

const User = require('../models/User');

/// Récupère le profil de l'utilisateur connecté avec ses enfants liés
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('-password')  // Exclut le mot de passe
      .populate('linkedChildren', 'fullName email');

    return res.json(user);
  } catch (error) {
    console.error('Erreur getProfile:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Récupère la liste des enfants liés à un parent
const getLinkedChildren = async (req, res) => {
  try {
    const parent = await User.findById(req.user.id)
      .populate('linkedChildren', 'fullName email');

    return res.json(parent.linkedChildren);
  } catch (error) {
    console.error('Erreur getLinkedChildren:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  getProfile,
  getLinkedChildren
};