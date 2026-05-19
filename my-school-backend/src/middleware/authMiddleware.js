const jwt = require('jsonwebtoken');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Parent = require('../models/Parent');
const Admin = require('../models/Admin');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Chercher l'utilisateur selon le rôle stocké dans le token
      switch(decoded.role) {
        case 'student':
          req.user = await Student.findById(decoded.id).select('-password');
          break;
        case 'teacher':
          req.user = await Teacher.findById(decoded.id).select('-password');
          break;
        case 'parent':
          req.user = await Parent.findById(decoded.id).select('-password');
          break;
        case 'admin':
          req.user = await Admin.findById(decoded.id).select('-password');
          break;
        default:
          req.user = null;
      }
      
      if (!req.user) {
        return res.status(401).json({ message: 'Utilisateur non trouvé' });
      }
      
      // Ajouter le rôle à req.user pour faciliter l'accès
      req.user.role = decoded.role;
      
      next();
    } catch (error) {
      console.error('❌ Erreur JWT:', error.message);
      return res.status(401).json({ message: 'Token invalide' });
    }
  } else {
    return res.status(401).json({ message: 'Non autorisé, pas de token' });
  }
};

module.exports = { protect };