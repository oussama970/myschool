const User = require('../models/User');
const VerificationCode = require('../models/VerificationCode');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const generateCode = require('../utils/generateCode');
const { sendVerificationEmail, sendParentCodeEmail, sendPasswordResetEmail } = require('../utils/emailService');

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });

// @desc    Inscription
// @route   POST /api/auth/register
const register = async (req, res) => {
  try {
    const { fullName, email, password, role } = req.body;

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    if (role === 'student') {
      const childCode = generateCode(6);
      const parentCode = generateCode(10);
      
      const student = await User.create({
        fullName,
        email: email.toLowerCase(),
        password: hashedPassword,
        role: 'student',
        childCode,
        parentCode,
        isVerified: false,
        linkedParents: []
      });

      await sendVerificationEmail(email, childCode, fullName);

      return res.status(201).json({
        success: true,
        message: 'Inscription réussie ! Vérifiez votre email.',
        token: generateToken(student._id),
        user: {
          id: student._id,
          fullName: student.fullName,
          email: student.email,
          role: student.role
        }
      });
    } else {
      const parent = await User.create({
        fullName,
        email: email.toLowerCase(),
        password: hashedPassword,
        role: 'parent',
        linkedChild: null
      });

      return res.status(201).json({
        success: true,
        message: 'Inscription réussie !',
        token: generateToken(parent._id),
        user: {
          id: parent._id,
          fullName: parent.fullName,
          email: parent.email,
          role: parent.role
        }
      });
    }
  } catch (error) {
    console.error('Erreur register:', error);
    return res.status(500).json({ message: 'Erreur lors de l\'inscription' });
  }
};

// @desc    Vérification email élève
// @route   POST /api/auth/verify-email
const verifyEmail = async (req, res) => {
  try {
    const { email, code } = req.body;

    const student = await User.findOne({ email: email.toLowerCase(), role: 'student' });
    if (!student) {
      return res.status(404).json({ message: 'Élève non trouvé' });
    }

    if (student.childCode !== code) {
      return res.status(400).json({ message: 'Code incorrect' });
    }

    student.isVerified = true;
    await student.save();

    await sendParentCodeEmail(email, student.parentCode, student.fullName);

    return res.json({
      success: true,
      message: 'Email vérifié !',
      parentCode: student.parentCode
    });
  } catch (error) {
    console.error('Erreur verifyEmail:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Connexion
// @route   POST /api/auth/login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }

    if (user.role === 'student' && !user.isVerified) {
      return res.status(403).json({
        message: 'Veuillez vérifier votre email',
        requiresVerification: true
      });
    }

    return res.json({
      success: true,
      message: 'Connexion réussie',
      token: generateToken(user._id),
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erreur login:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Vérifier le code parent (première liaison)
// @route   POST /api/auth/verify-parent-code
const verifyParentCode = async (req, res) => {
  try {
    const { parentCode } = req.body;

    console.log('🔍 Vérification code parent reçu:', parentCode);
    console.log('👤 Utilisateur authentifié ID:', req.user?.id);

    if (!req.user) {
      return res.status(401).json({ 
        success: false,
        message: 'Non authentifié' 
      });
    }

    // Chercher l'enfant avec ce code parent
    const child = await User.findOne({
      parentCode: parentCode,
      role: 'student',
      isVerified: true
    });

    console.log('👦 Enfant trouvé:', child ? child.fullName : 'Aucun');

    if (!child) {
      return res.status(404).json({
        success: false,
        message: 'Code invalide. Aucun élève trouvé avec ce code.'
      });
    }

    // Récupérer le parent
    const parent = await User.findById(req.user.id);
    console.log('👨 Parent trouvé:', parent ? parent.email : 'Aucun');

    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ 
        success: false,
        message: 'Parent non trouvé' 
      });
    }

    // LIER L'ENFANT AU PARENT
    parent.linkedChild = child._id;
    await parent.save();
    console.log('✅ Parent lié à l\'enfant:', child._id);

    // Ajouter le parent à la liste des parents liés de l'enfant
    if (!child.linkedParents.includes(parent.email)) {
      child.linkedParents.push(parent.email);
      await child.save();
      console.log('✅ Enfant mis à jour avec parent:', parent.email);
    }

    return res.json({
      success: true,
      message: `✅ Enfant ${child.fullName} lié avec succès !`,
      child: {
        id: child._id,
        fullName: child.fullName,
        email: child.email
      }
    });
  } catch (error) {
    console.error('❌ Erreur verifyParentCode:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

// @desc    Récupérer les informations d'un enfant
// @route   GET /api/auth/child/:email
const getChildInfo = async (req, res) => {
  try {
    const { email } = req.params;
    const child = await User.findOne({ email: email.toLowerCase(), role: 'student' })
      .select('fullName email parentCode');
    
    if (!child) {
      return res.status(404).json({ message: 'Enfant non trouvé' });
    }

    return res.json({
      success: true,
      fullName: child.fullName,
      email: child.email,
      parentCode: child.parentCode
    });
  } catch (error) {
    console.error('Erreur getChildInfo:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Récupérer l'enfant lié à un parent
// @route   GET /api/auth/linked-child/:email
const getLinkedChild = async (req, res) => {
  try {
    const { email } = req.params;
    console.log('🔍 Recherche enfant lié pour parent:', email);

    const parent = await User.findOne({ 
      email: email.toLowerCase(), 
      role: 'parent' 
    }).populate('linkedChild', 'fullName email parentCode');

    if (!parent) {
      console.log('❌ Parent non trouvé');
      return res.status(404).json({ 
        success: false,
        message: 'Parent non trouvé' 
      });
    }

    console.log('👨 Parent trouvé, linkedChild:', parent.linkedChild);

    if (!parent.linkedChild) {
      return res.status(404).json({ 
        success: false,
        message: 'Aucun enfant lié' 
      });
    }

    return res.json({
      success: true,
      child: {
        id: parent.linkedChild._id,
        fullName: parent.linkedChild.fullName,
        email: parent.linkedChild.email
      }
    });
  } catch (error) {
    console.error('❌ Erreur getLinkedChild:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

// @desc    Récupérer tous les enfants d'un parent
// @route   GET /api/auth/parent-children/:email
const getParentChildren = async (req, res) => {
  try {
    const { email } = req.params;
    
    return res.json({
      success: true,
      children: []
    });
  } catch (error) {
    console.error('Erreur getParentChildren:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Demande de réinitialisation
// @route   POST /api/auth/forgot-password
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'Aucun compte avec cet email' });
    }

    const code = generateCode(6);

    await VerificationCode.create({
      email: email.toLowerCase(),
      code,
      type: 'password_reset'
    });

    await sendPasswordResetEmail(email, code);

    return res.json({ 
      success: true,
      message: 'Code de réinitialisation envoyé',
      email: email.toLowerCase()
    });

  } catch (error) {
    console.error('Erreur forgotPassword:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// @desc    Réinitialiser le mot de passe
// @route   POST /api/auth/reset-password
const resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    const verification = await VerificationCode.findOne({
      email: email.toLowerCase(),
      code,
      type: 'password_reset',
      used: false
    });

    if (!verification) {
      return res.status(400).json({ message: 'Code invalide ou expiré' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await User.findOneAndUpdate(
      { email: email.toLowerCase() },
      { password: hashedPassword }
    );

    verification.used = true;
    await verification.save();

    return res.json({ 
      success: true,
      message: 'Mot de passe réinitialisé avec succès' 
    });

  } catch (error) {
    console.error('Erreur resetPassword:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = {
  register,
  verifyEmail,
  login,
  verifyParentCode,
  getChildInfo,
  getLinkedChild,
  getParentChildren,
  forgotPassword,
  resetPassword
};