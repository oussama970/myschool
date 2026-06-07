// backend/src/controllers/authController.js
/// Contrôleur d'authentification pour la gestion des utilisateurs (register, login, vérification email, mot de passe oublié)
/// Gère les 4 rôles: student, teacher, parent, admin avec des modèles distincts

const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Parent = require('../models/Parent');
const Admin = require('../models/Admin');
const VerificationCode = require('../models/VerificationCode');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const generateCode = require('../utils/generateCode');
const { sendVerificationEmail, sendParentCodeEmail, sendPasswordResetEmail } = require('../utils/emailService');

/// Génère un token JWT pour l'utilisateur authentifié
const generateToken = (id, role) => jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: '30d' });

/// Inscription d'un nouvel utilisateur (étudiant ou parent)
const register = async (req, res) => {
  try {
    const { fullName, email, password, role } = req.body;
    let existingUser = null;
    
    // Vérification selon le rôle
    switch(role) {
      case 'student': existingUser = await Student.findOne({ email: email.toLowerCase() }); break;
      case 'teacher': existingUser = await Teacher.findOne({ email: email.toLowerCase() }); break;
      case 'parent': existingUser = await Parent.findOne({ email: email.toLowerCase() }); break;
      case 'admin': existingUser = await Admin.findOne({ email: email.toLowerCase() }); break;
      default: return res.status(400).json({ message: 'Rôle invalide' });
    }

    if (existingUser) return res.status(400).json({ message: 'Cet email est déjà utilisé' });

    // Hachage du mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Inscription étudiant (avec codes childCode et parentCode)
    if (role === 'student') {
      const childCode = generateCode(6);
      const parentCode = generateCode(10);
      const student = await Student.create({ 
        fullName, 
        email: email.toLowerCase(), 
        password: hashedPassword, 
        childCode, 
        parentCode, 
        isVerified: false, 
        linkedParents: [] 
      });
      await sendVerificationEmail(email, childCode, fullName);
      return res.status(201).json({ 
        success: true, 
        message: 'Inscription réussie ! Vérifiez votre email.', 
        token: generateToken(student._id, 'student'), 
        user: { id: student._id, fullName: student.fullName, email: student.email, role: 'student' } 
      });
    } 
    // Inscription parent
    else if (role === 'parent') {
      const parent = await Parent.create({ 
        fullName, 
        email: email.toLowerCase(), 
        password: hashedPassword, 
        linkedChildren: [] 
      });
      return res.status(201).json({ 
        success: true, 
        message: 'Inscription réussie !', 
        token: generateToken(parent._id, 'parent'), 
        user: { id: parent._id, fullName: parent.fullName, email: parent.email, role: 'parent' } 
      });
    }
    else {
      return res.status(400).json({ message: 'Rôle non supporté pour l\'inscription' });
    }
  } catch (error) {
    console.error('Erreur register:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Vérification de l'email de l'étudiant avec le code reçu
const verifyEmail = async (req, res) => {
  try {
    const { email, code } = req.body;
    const student = await Student.findOne({ email: email.toLowerCase() });
    if (!student) return res.status(404).json({ message: 'Élève non trouvé' });
    if (student.childCode !== code) return res.status(400).json({ message: 'Code incorrect' });
    
    student.isVerified = true;
    await student.save();
    await sendParentCodeEmail(email, student.parentCode, student.fullName);
    
    return res.json({ success: true, message: 'Email vérifié !', parentCode: student.parentCode });
  } catch (error) {
    console.error('Erreur verifyEmail:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Connexion d'un utilisateur (tous rôles confondus)
const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const emailLower = email.toLowerCase();
    
    // Recherche séquentielle dans les 4 modèles
    let user = await Student.findOne({ email: emailLower });
    let role = 'student';
    
    if (!user) { user = await Teacher.findOne({ email: emailLower }); role = 'teacher'; }
    if (!user) { user = await Parent.findOne({ email: emailLower }); role = 'parent'; }
    if (!user) { user = await Admin.findOne({ email: emailLower }); role = 'admin'; }
    
    if (!user) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    
    // Vérification du mot de passe
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    
    // Vérification email pour les étudiants
    if (role === 'student' && !user.isVerified) {
      return res.status(403).json({ message: 'Veuillez vérifier votre email', requiresVerification: true });
    }
    
    return res.json({ 
      success: true, 
      message: 'Connexion réussie', 
      token: generateToken(user._id, role), 
      user: { id: user._id, fullName: user.fullName, email: user.email, role: role } 
    });
  } catch (error) {
    console.error('Erreur login:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Vérification du code parent pour lier un parent à son enfant
const verifyParentCode = async (req, res) => {
  try {
    const { parentCode } = req.body;
    if (!req.user) return res.status(401).json({ success: false, message: 'Non authentifié' });
    
    const child = await Student.findOne({ parentCode, isVerified: true });
    if (!child) return res.status(404).json({ success: false, message: 'Code invalide' });
    
    const parent = await Parent.findById(req.user.id);
    if (!parent) return res.status(403).json({ success: false, message: 'Parent non trouvé' });
    
    // Lier l'enfant au parent
    if (!parent.linkedChildren.includes(child._id)) {
      parent.linkedChildren.push(child._id);
      await parent.save();
    }
    
    // Lier le parent à l'enfant
    if (!child.linkedParents.includes(parent.email)) {
      child.linkedParents.push(parent.email);
      await child.save();
    }
    
    return res.json({ 
      success: true, 
      message: `✅ Enfant ${child.fullName} lié avec succès !`, 
      child: { id: child._id, fullName: child.fullName, email: child.email } 
    });
  } catch (error) {
    console.error('Erreur:', error);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère les informations d'un enfant par email (pour le parent)
const getChildInfo = async (req, res) => {
  try {
    const { email } = req.params;
    const child = await Student.findOne({ email: email.toLowerCase() }).select('fullName email parentCode');
    if (!child) return res.status(404).json({ message: 'Enfant non trouvé' });
    return res.json({ success: true, fullName: child.fullName, email: child.email, parentCode: child.parentCode });
  } catch (error) {
    console.error('Erreur:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Récupère le premier enfant lié à un parent
const getLinkedChild = async (req, res) => {
  try {
    const { email } = req.params;
    const parent = await Parent.findOne({ email: email.toLowerCase() }).populate('linkedChildren', 'fullName email');
    if (!parent) return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    if (!parent.linkedChildren || parent.linkedChildren.length === 0) return res.status(404).json({ success: false, message: 'Aucun enfant lié' });
    const firstChild = parent.linkedChildren[0];
    return res.json({ success: true, child: { id: firstChild._id, fullName: firstChild.fullName, email: firstChild.email } });
  } catch (error) {
    console.error('Erreur:', error);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Récupère tous les enfants liés à un parent
const getParentChildren = async (req, res) => {
  try {
    const { email } = req.params;
    const parent = await Parent.findOne({ email: email.toLowerCase() }).populate('linkedChildren', 'fullName email className childCode');
    if (!parent) return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    const children = parent.linkedChildren || [];
    return res.json({ 
      success: true, 
      children: children.map(child => ({ 
        id: child._id, 
        fullName: child.fullName, 
        email: child.email, 
        className: child.className, 
        childCode: child.childCode 
      })) 
    });
  } catch (error) {
    console.error('Erreur:', error);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/// Demande de réinitialisation de mot de passe (envoi d'un code)
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const emailLower = email.toLowerCase();
    
    // Recherche dans tous les modèles
    let user = await Student.findOne({ email: emailLower });
    if (!user) user = await Teacher.findOne({ email: emailLower });
    if (!user) user = await Parent.findOne({ email: emailLower });
    if (!user) user = await Admin.findOne({ email: emailLower });
    
    if (!user) return res.status(404).json({ message: 'Aucun compte avec cet email' });
    
    const code = generateCode(6);
    await VerificationCode.create({ email: emailLower, code, type: 'password_reset' });
    await sendPasswordResetEmail(email, code);
    
    return res.json({ success: true, message: 'Code de réinitialisation envoyé', email: emailLower });
  } catch (error) {
    console.error('Erreur:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

/// Réinitialisation du mot de passe avec le code reçu
const resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    const emailLower = email.toLowerCase();
    
    // Vérification du code
    const verification = await VerificationCode.findOne({ email: emailLower, code, type: 'password_reset', used: false });
    if (!verification) return res.status(400).json({ message: 'Code invalide ou expiré' });
    
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Mise à jour du mot de passe dans le bon modèle
    let updated = false;
    let student = await Student.findOne({ email: emailLower });
    if (student) { student.password = hashedPassword; await student.save(); updated = true; }
    
    if (!updated) { let teacher = await Teacher.findOne({ email: emailLower }); if (teacher) { teacher.password = hashedPassword; await teacher.save(); updated = true; } }
    if (!updated) { let parent = await Parent.findOne({ email: emailLower }); if (parent) { parent.password = hashedPassword; await parent.save(); updated = true; } }
    if (!updated) { let admin = await Admin.findOne({ email: emailLower }); if (admin) { admin.password = hashedPassword; await admin.save(); updated = true; } }
    
    if (!updated) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    
    verification.used = true;
    await verification.save();
    
    return res.json({ success: true, message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    console.error('Erreur:', error);
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