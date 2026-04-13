const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./src/config/database');

// Charger les variables d'environnement
dotenv.config();

// Connexion à MongoDB
connectDB();

const app = express();

// Middleware CORS - Configuration complète
app.use(cors({
  origin: [
    'http://localhost:8080',
    'http://10.0.2.2:8080',
    'http://127.0.0.1:8080',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://10.0.2.2:5000'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logger middleware (optionnel)
app.use((req, res, next) => {
  console.log(`📝 ${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/teacher', require('./src/routes/teacherRoutes'));
app.use('/api/users', require('./src/routes/userRoutes'));

// Route de test
app.get('/api/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'API MySchool opérationnelle',
    timestamp: new Date().toISOString()
  });
});

// Route racine
app.get('/', (req, res) => {
  res.json({ 
    success: true,
    message: 'API MySchool opérationnelle',
    endpoints: {
      auth: '/api/auth',
      admin: '/api/admin',
      teacher: '/api/teacher',
      users: '/api/users'
    }
  });
});

// Middleware 404 pour les routes non trouvées
app.use((req, res) => {
  res.status(404).json({ 
    success: false,
    message: `Route ${req.method} ${req.url} non trouvée` 
  });
});

// Middleware de gestion d'erreurs global
app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err.stack);
  res.status(500).json({ 
    success: false,
    message: 'Erreur interne du serveur',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Démarrage du serveur
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`\n🚀 Serveur démarré sur le port ${PORT}`);
  

});