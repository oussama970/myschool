// src/controllers/adminController.js
const User = require('../models/User');
const bcrypt = require('bcryptjs');

// @desc    Créer un administrateur (nécessite un admin existant)
// @route   POST /api/admin/create
const createAdmin = async (req, res) => {
  try {
    // Vérifier que l'utilisateur connecté est admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        success: false,
        message: 'Accès non autorisé' 
      });
    }

    const { fullName, email, password } = req.body;

    // Validation
    if (!fullName || !email || !password) {
      return res.status(400).json({ 
        success: false,
        message: 'Tous les champs sont requis' 
      });
    }

    if (password.length < 8) {
      return res.status(400).json({ 
        success: false,
        message: 'Le mot de passe doit contenir au moins 8 caractères' 
      });
    }

    // Vérifier si l'email existe déjà
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ 
        success: false,
        message: 'Cet email est déjà utilisé' 
      });
    }

    // Hasher le mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Créer l'admin
    const admin = await User.create({
      fullName,
      email: email.toLowerCase(),
      password: hashedPassword,
      role: 'admin',
      isVerified: true
    });

    res.status(201).json({
      success: true,
      message: 'Administrateur créé avec succès',
      admin: {
        id: admin._id,
        fullName: admin.fullName,
        email: admin.email,
        role: admin.role,
        createdAt: admin.createdAt
      }
    });
  } catch (error) {
    console.error('Erreur création admin:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

// @desc    Liste tous les utilisateurs (admin seulement)
// @route   GET /api/admin/users
const getAllUsers = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        success: false,
        message: 'Accès non autorisé' 
      });
    }

    const users = await User.find()
      .select('-password')
      .sort('-createdAt');

    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (error) {
    console.error('Erreur liste users:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

// @desc    Supprimer un utilisateur (admin seulement)
// @route   DELETE /api/admin/users/:id
const deleteUser = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        success: false,
        message: 'Accès non autorisé' 
      });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'Utilisateur non trouvé' 
      });
    }

    // Empêcher la suppression de son propre compte
    if (user._id.toString() === req.user.id) {
      return res.status(400).json({ 
        success: false,
        message: 'Vous ne pouvez pas supprimer votre propre compte' 
      });
    }

    await user.deleteOne();

    res.json({
      success: true,
      message: 'Utilisateur supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur suppression:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

module.exports = {
  createAdmin,
  getAllUsers,
  deleteUser
};