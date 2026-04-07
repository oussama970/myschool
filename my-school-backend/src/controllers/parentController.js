const User = require('../models/User');

const getAllParents = async (req, res) => {
  try {
    const parents = await User.find({ role: 'parent' }).select('-password').sort('-createdAt');
    res.json({ success: true, parents });
  } catch (error) {
    console.error('Erreur récupération parents:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

const deleteParent = async (req, res) => {
  try {
    const parent = await User.findById(req.params.id);
    if (!parent || parent.role !== 'parent') {
      return res.status(404).json({ message: 'Parent non trouvé' });
    }
    await parent.deleteOne();
    res.json({ success: true, message: 'Parent supprimé' });
  } catch (error) {
    console.error('Erreur suppression parent:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { getAllParents, deleteParent };