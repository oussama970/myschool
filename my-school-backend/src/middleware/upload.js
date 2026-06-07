// backend/src/middleware/upload.js
/// Middleware de configuration Multer pour l'upload de fichiers
/// Permet d'accepter plusieurs types de fichiers (images, PDF, documents Office, vidéos, audios)

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Création du dossier uploads s'il n'existe pas
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

/// Configuration du stockage des fichiers
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    // Génération d'un nom unique (timestamp + nombre aléatoire)
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

/// Filtre pour accepter les types de fichiers courants
const fileFilter = (req, file, cb) => {
  // Types MIME acceptés
  const allowedTypes = [
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/csv',
    'video/mp4',
    'video/mpeg',
    'audio/mpeg',
    'audio/mp3'
  ];
  
  // Extensions acceptées
  const allowedExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', 
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', 
    '.ppt', '.pptx', '.txt', '.csv', 
    '.mp4', '.mp3'
  ];
  const ext = path.extname(file.originalname).toLowerCase();
  
  if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
    cb(null, true);
  } else {
    console.log('❌ Type de fichier non supporté:', file.mimetype, 'Extension:', ext);
    cb(new Error('Type de fichier non supporté'), false);
  }
};

/// Configuration Multer avec limite de taille (50MB max)
const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB max
});

module.exports = upload;