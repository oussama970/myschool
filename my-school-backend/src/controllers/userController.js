const User = require('../models/User');

// @desc    Obtenir le profil
// @route   GET /api/users/profile
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('-password')
      .populate('linkedChildren', 'fullName email');

    return res.json(user);
  } catch (error) {
    console.error('Erreur getProfile:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Obtenir les enfants liés
// @route   GET /api/users/children
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