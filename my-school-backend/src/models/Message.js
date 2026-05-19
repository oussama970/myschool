const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  senderId: {
    type: String,  // ← Changement crucial: de ObjectId à String
    required: true
  },
  senderName: {
    type: String,
    required: true
  },
  senderRole: {
    type: String,
    enum: ['teacher', 'parent', 'student', 'admin'],
    required: true
  },
  receiverId: {
    type: String,  // ← Changement crucial: de ObjectId à String
    required: true
  },
  receiverName: {
    type: String,
    required: true
  },
  receiverRole: {
    type: String,
    enum: ['teacher', 'parent', 'student', 'admin'],
    required: true
  },
  message: {
    type: String,
    required: true
  },
  isRead: {
    type: Boolean,
    default: false
  },
  attachments: [{
    filename: String,
    originalName: String,
    fileType: String,
    fileSize: Number,
    filePath: String
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index pour faciliter les recherches
messageSchema.index({ senderId: 1 });
messageSchema.index({ receiverId: 1 });
messageSchema.index({ createdAt: -1 });
messageSchema.index({ isRead: 1 });

module.exports = mongoose.model('Message', messageSchema);