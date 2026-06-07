const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Email de vérification pour les élèves
const sendVerificationEmail = async (email, code, fullName) => {
  const mailOptions = {
    from: `"MySchool" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: '🎓 MySchool - Code de vérification',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h1 style="color: #0288D1; text-align: center;">Bienvenue sur MySchool !</h1>
        <p>Bonjour <strong>${fullName}</strong>,</p>
        <p>Voici votre code de vérification à 6 chiffres :</p>
        <div style="background-color: #f0f8ff; padding: 20px; text-align: center; border-radius: 10px; margin: 20px 0;">
          <h2 style="color: #0288D1; font-size: 48px; letter-spacing: 10px; margin: 0;">${code}</h2>
        </div>
        <p>Ce code expirera dans 15 minutes.</p>
      </div>
    `
  };
  await transporter.sendMail(mailOptions);
};

// Email avec le code parent
const sendParentCodeEmail = async (email, code, fullName) => {
  const mailOptions = {
    from: `"MySchool" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: '👪 MySchool - Code pour vos parents',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h1 style="color: #4CAF9F; text-align: center;">Code pour vos parents</h1>
        <p>Bonjour <strong>${fullName}</strong>,</p>
        <p>Voici le code à 10 chiffres à communiquer à vos parents :</p>
        <div style="background-color: #e8f5e9; padding: 20px; text-align: center; border-radius: 10px; margin: 20px 0;">
          <h2 style="color: #4CAF9F; font-size: 48px; letter-spacing: 5px; margin: 0;">${code}</h2>
        </div>
        <p>Ce code permettra à vos parents de se connecter à votre espace.</p>
      </div>
    `
  };
  await transporter.sendMail(mailOptions);
};

// Email de réinitialisation de mot de passe
const sendPasswordResetEmail = async (email, code) => {
  const mailOptions = {
    from: `"MySchool" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: '🔐 MySchool - Réinitialisation de mot de passe',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h1 style="color: #FFB74D; text-align: center;">Réinitialisation de mot de passe</h1>
        <p>Voici votre code de réinitialisation :</p>
        <div style="background-color: #fff3e0; padding: 20px; text-align: center; border-radius: 10px; margin: 20px 0;">
          <h2 style="color: #FFB74D; font-size: 48px; letter-spacing: 10px; margin: 0;">${code}</h2>
        </div>
        <p>Ce code expirera dans 15 minutes.</p>
      </div>
    `
  };
  await transporter.sendMail(mailOptions);
};

// Email pour les enseignants 
const sendTeacherCredentialsEmail = async (email, fullName, password) => {
  console.log(`📧 Tentative d'envoi d'email à l'enseignant: ${email}`);
  
  const mailOptions = {
    from: `"MySchool" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: '🎓 MySchool - Vos identifiants enseignant',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h1 style="color: #0288D1; text-align: center;">Bienvenue dans l'équipe pédagogique !</h1>
        <p>Bonjour <strong>${fullName}</strong>,</p>
        <p>Votre compte enseignant a été créé. Voici vos identifiants de connexion :</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>📧 Email :</strong> ${email}</p>
          <p><strong>🔑 Mot de passe :</strong> <span style="background-color: #fff; padding: 4px 8px; border-radius: 5px;">${password}</span></p>
        </div>
        <p>Connectez-vous à l'application MySchool pour accéder à votre espace.</p>
        <p style="color: #666; font-size: 12px; margin-top: 20px;">Ce message est automatique, merci de ne pas y répondre.</p>
      </div>
    `
  };
  
  try {
    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Email enseignant envoyé avec succès à ${email}`);
    console.log(`📨 Message ID: ${result.messageId}`);
    return result;
  } catch (error) {
    console.error(`❌ Erreur détaillée lors de l'envoi à ${email}:`, error.message);
    console.error(`Code d'erreur:`, error.code);
    throw error;
  }
};

module.exports = {
  sendVerificationEmail,
  sendParentCodeEmail,
  sendPasswordResetEmail,
  sendTeacherCredentialsEmail
};