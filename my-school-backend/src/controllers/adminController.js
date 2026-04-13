const User = require('../models/User');
const bcrypt = require('bcryptjs');

// @desc    Créer un administrateur (nécessite un admin existant)
// @route   POST /api/admin/create
// @access  Private/Admin
const createAdmin = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        success: false,
        message: 'Accès non autorisé' 
      });
    }

    const { fullName, email, password } = req.body;

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

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ 
        success: false,
        message: 'Cet email est déjà utilisé' 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

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
// @access  Private/Admin
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
// @access  Private/Admin
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

// @desc    Obtenir le profil admin
// @route   GET /api/admin/profile/:email
// @access  Private/Admin
const getAdminProfile = async (req, res) => {
  try {
    const { email } = req.params;
    const admin = await User.findOne({ email: email.toLowerCase(), role: 'admin' }).select('-password');
    
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin non trouvé' });
    }
    
    res.json({
      success: true,
      fullName: admin.fullName,
      email: admin.email,
      phoneNumber: admin.phoneNumber || '',
      createdAt: admin.createdAt,
      lastLogin: admin.lastLogin || null,
    });
  } catch (error) {
    console.error('Erreur getAdminProfile:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Mettre à jour le profil admin
// @route   PUT /api/admin/profile
// @access  Private/Admin
const updateAdminProfile = async (req, res) => {
  try {
    const { email, fullName, phoneNumber } = req.body;
    
    const admin = await User.findOne({ email: email.toLowerCase(), role: 'admin' });
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin non trouvé' });
    }
    
    if (fullName) admin.fullName = fullName;
    if (phoneNumber) admin.phoneNumber = phoneNumber;
    
    await admin.save();
    
    res.json({
      success: true,
      message: 'Profil mis à jour',
      admin: {
        fullName: admin.fullName,
        email: admin.email,
        phoneNumber: admin.phoneNumber,
      }
    });
  } catch (error) {
    console.error('Erreur updateAdminProfile:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Changer le mot de passe admin
// @route   POST /api/admin/change-password
// @access  Private/Admin
const changeAdminPassword = async (req, res) => {
  try {
    const { email, currentPassword, newPassword } = req.body;
    
    const admin = await User.findOne({ email: email.toLowerCase(), role: 'admin' });
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin non trouvé' });
    }
    
    const isMatch = await bcrypt.compare(currentPassword, admin.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Mot de passe actuel incorrect' });
    }
    
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    admin.password = hashedPassword;
    
    await admin.save();
    
    res.json({ success: true, message: 'Mot de passe modifié avec succès' });
  } catch (error) {
    console.error('Erreur changeAdminPassword:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  createAdmin,
  getAllUsers,
  deleteUser,
  getAdminProfile,
  updateAdminProfile,
  changeAdminPassword,
};