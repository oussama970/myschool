const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  console.log('🔍 Headers reçus:', req.headers);

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      console.log('🔑 Token extrait:', token.substring(0, 20) + '...');
      
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log('👤 Utilisateur décodé:', decoded);
      
      req.user = await User.findById(decoded.id).select('-password');
      console.log('✅ Utilisateur trouvé:', req.user?.email);
      
      if (!req.user) {
        return res.status(401).json({ message: 'Utilisateur non trouvé' });
      }
      
      next();
    } catch (error) {
      console.error('❌ Erreur JWT:', error.message);
      return res.status(401).json({ message: 'Token invalide' });
    }
  } else {
    console.log('❌ Pas de Bearer token dans Authorization');
    console.log('Authorization header:', req.headers.authorization);
    return res.status(401).json({ message: 'Non autorisé, pas de token' });
  }
};

module.exports = { protect };