const Admin = require('../models/Admin');
const bcrypt = require('bcryptjs');

const getAdminProfile = async (req, res) => {
  try {
    const { email } = req.params;
    const admin = await Admin.findOne({ email: email.toLowerCase() }).select('-password');
    
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin non trouvé' });
    }
    
    res.json({ success: true, fullName: admin.fullName, email: admin.email, phoneNumber: admin.phoneNumber || '', createdAt: admin.createdAt, lastLogin: admin.lastLogin || null });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const updateAdminProfile = async (req, res) => {
  try {
    const { email, fullName, phoneNumber } = req.body;
    
    const admin = await Admin.findOne({ email: email.toLowerCase() });
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin non trouvé' });
    }
    
    if (fullName) admin.fullName = fullName;
    if (phoneNumber) admin.phoneNumber = phoneNumber;
    
    await admin.save();
    
    res.json({ success: true, message: 'Profil mis à jour', admin: { fullName: admin.fullName, email: admin.email, phoneNumber: admin.phoneNumber } });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const changeAdminPassword = async (req, res) => {
  try {
    const { email, currentPassword, newPassword } = req.body;
    
    const admin = await Admin.findOne({ email: email.toLowerCase() });
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
    
    res.json({ success: true, message: 'Mot de passe modifié' });
  } catch (error) {
    console.error('Erreur:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getAdminProfile, updateAdminProfile, changeAdminPassword };