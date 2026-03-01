const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

const sendVerificationEmail = async (email, code, fullName) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: '🎓 My School - Code de vérification',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h1 style="color: #0288D1; text-align: center;">Bienvenue sur My School !</h1>
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

const sendParentCodeEmail = async (email, code, fullName) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: '👪 My School - Code pour vos parents',
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

const sendPasswordResetEmail = async (email, code) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: '🔐 My School - Réinitialisation de mot de passe',
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

module.exports = {
  sendVerificationEmail,
  sendParentCodeEmail,
  sendPasswordResetEmail
};