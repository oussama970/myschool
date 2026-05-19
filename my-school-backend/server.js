const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
const connectDB = require('./src/config/database');
const path = require('path');
const fs = require('fs');
const http = require('http');
const socketIo = require('socket.io');

// Charger les variables d'environnement
dotenv.config();

// Connexion à MongoDB
connectDB();

const app = express();

// Créer le dossier uploads s'il n'existe pas
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log('📁 Dossier uploads créé');
}

// Rate limiting
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { success: false, message: 'Trop de tentatives, veuillez réessayer dans 15 minutes' },
  skipSuccessfulRequests: true,
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: { success: false, message: 'Trop de requêtes, veuillez réessayer plus tard' },
});

// CORS
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:8080', 'http://10.0.2.2:8080', 'http://127.0.0.1:8080', 'http://localhost:3000'];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use('/uploads', express.static(uploadDir));

// Logger
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      const status = res.statusCode;
      const color = status >= 500 ? '\x1b[31m' : (status >= 400 ? '\x1b[33m' : '\x1b[32m');
      console.log(`📝 ${req.method} ${req.url} - ${color}${status}\x1b[0m - ${duration}ms`);
    });
    next();
  });
}

// ==================== ROUTES API ====================
app.use('/api/auth', loginLimiter, require('./src/routes/authRoutes'));
app.use('/api/admin', apiLimiter, require('./src/routes/adminRoutes'));
app.use('/api/teacher', apiLimiter, require('./src/routes/teacherRoutes'));
app.use('/api/users', apiLimiter, require('./src/routes/userRoutes'));
app.use('/api/messages', apiLimiter, require('./src/routes/messageRoutes'));
app.use('/api/student', apiLimiter, require('./src/routes/studentRoutes'));
app.use('/api', apiLimiter, require('./src/routes/eventRoutes'));
app.use('/api/parent', apiLimiter, require('./src/routes/parentRoutes'));

// Route de test
app.get('/api/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'API MySchool opérationnelle',
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    status: 'OK',
    uptime: process.uptime(),
  });
});

// Middleware 404
app.use((req, res) => {
  res.status(404).json({ 
    success: false,
    message: `Route ${req.method} ${req.url} non trouvée`,
  });
});

// Middleware d'erreur
app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err.stack);
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ success: false, message: 'Fichier trop volumineux. Taille maximale: 50MB' });
  }
  res.status(500).json({ 
    success: false,
    message: 'Erreur interne du serveur',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// ==================== SOCKET.IO ====================
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST']
  }
});

// Stocker les utilisateurs connectés
const connectedUsers = new Map(); // userId -> socketId
const userSockets = new Map(); // socketId -> userId

io.on('connection', (socket) => {
  console.log('🟢 Nouveau client connecté:', socket.id);
  
  // Authentifier l'utilisateur
  socket.on('authenticate', (userId) => {
    if (connectedUsers.has(userId)) {
      const oldSocketId = connectedUsers.get(userId);
      if (oldSocketId !== socket.id) {
        io.to(oldSocketId).emit('force_logout');
        userSockets.delete(oldSocketId);
      }
    }
    
    connectedUsers.set(userId, socket.id);
    userSockets.set(socket.id, userId);
    console.log(`✅ Utilisateur ${userId} authentifié (${connectedUsers.size} connectés)`);
    socket.emit('authenticated', { success: true });
  });
  
  // Envoyer un message (via WebSocket uniquement)
  socket.on('send_message', async (data) => {
    const { 
      receiverId, 
      receiverName, 
      receiverRole, 
      message, 
      senderId, 
      senderName, 
      senderRole,
      attachments, 
      tempId 
    } = data;
    
    console.log('========== MESSAGE WEBSOCKET ==========');
    console.log('📨 De:', senderId, '(' + (senderRole || 'non spécifié') + ')');
    console.log('📨 À:', receiverId, '(' + receiverRole + ')');
    console.log('📨 Message:', message?.substring(0, 50));
    
    try {
      const Message = require('./src/models/Message');
      
      // Définir senderRole par défaut si non fourni
      const finalSenderRole = senderRole || 'parent';
      
      const newMessage = await Message.create({
        senderId: senderId,
        senderName: senderName,
        senderRole: finalSenderRole,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverRole: receiverRole,
        message: message,
        attachments: attachments || [],
        isRead: false
      });
      
      console.log(`✅ Message sauvegardé: ${newMessage._id} (role: ${finalSenderRole})`);
      
      // Envoyer au destinataire s'il est connecté
      const receiverSocketId = connectedUsers.get(receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('new_message', newMessage);
        console.log(`📤 Message envoyé en temps réel à ${receiverId}`);
      } else {
        console.log(`⚠️ Destinataire ${receiverId} non connecté`);
      }
      
      // Confirmer à l'expéditeur
      socket.emit('message_sent', { 
        success: true, 
        message: newMessage,
        tempId: tempId 
      });
      
    } catch (error) {
      console.error('❌ Erreur sauvegarde message:', error);
      socket.emit('message_error', { error: error.message, tempId: tempId });
    }
  });
  
  // Marquer un message comme lu
  socket.on('mark_as_read', async (data) => {
    const { messageId, senderId } = data;
    const readerId = userSockets.get(socket.id);
    
    try {
      const Message = require('./src/models/Message');
      await Message.findByIdAndUpdate(messageId, { isRead: true });
      console.log(`📖 Message ${messageId} marqué comme lu par ${readerId}`);
      
      const senderSocketId = connectedUsers.get(senderId);
      if (senderSocketId) {
        io.to(senderSocketId).emit('message_read', { messageId, readerId });
      }
    } catch (error) {
      console.error('Erreur mark_as_read:', error);
    }
  });
  
  // L'utilisateur tape un message
  socket.on('typing', (data) => {
    const { receiverId, isTyping } = data;
    const senderId = userSockets.get(socket.id);
    const receiverSocketId = connectedUsers.get(receiverId);
    
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('user_typing', {
        userId: senderId,
        isTyping: isTyping
      });
    }
  });
  
  // Déconnexion
  socket.on('disconnect', () => {
    const userId = userSockets.get(socket.id);
    if (userId) {
      connectedUsers.delete(userId);
      userSockets.delete(socket.id);
      console.log(`🔴 Utilisateur ${userId} déconnecté (${connectedUsers.size} restants)`);
    }
  });
});

// Gestion des signaux d'arrêt
process.on('SIGINT', () => {
  console.log('\n🛑 Serveur arrêté par SIGINT');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Serveur arrêté par SIGTERM');
  process.exit(0);
});

// Démarrage
const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n========================================');
  console.log('🚀 SERVEUR DÉMARRÉ AVEC SUCCÈS');
  console.log('========================================');
  console.log(`📡 Port: ${PORT}`);
  console.log(`🌐 URL: http://localhost:${PORT}`);
  console.log(`📱 URL émulateur: http://10.0.2.2:${PORT}`);
  console.log(`📁 Dossier uploads: ${uploadDir}`);
  console.log(`🔒 Rate limiting: 100 req/min, 5 tentatives login/15min`);
  console.log(`🔌 WebSocket: activé (Socket.IO)`);
  console.log('========================================\n');
});

module.exports = { app, server, io };