const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
    // SUPPRIMÉ: unique: true (sera défini dans schema.index)
  },
  password: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['student', 'parent', 'admin', 'teacher'],
    required: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  
  // Pour les enseignants
  phoneNumber: {
    type: String,
    default: ''
  },
  subjects: [{
    type: String
  }],
  assignedClasses: [{
    type: String
  }],
  
  // Pour les élèves
  childCode: {
    type: String
    // SUPPRIMÉ: unique, sparse
  },
  parentCode: {
    type: String
    // SUPPRIMÉ: unique, sparse
  },
  className: {
    type: String,
    default: ''
  },
  
  // Pour les parents
  linkedChildren: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  
  linkedParents: [{
    type: String,
    lowercase: true
  }],
  
  // Notes et appréciations (pour les élèves)
  grades: [{
    subject: {
      type: String,
      required: true
    },
    grade: {
      type: Number,
      required: true,
      min: 0,
      max: 20
    },
    appreciation: {
      type: String,
      default: ''
    },
    date: {
      type: Date,
      default: Date.now
    },
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    teacherName: {
      type: String,
      default: ''
    }
  }],
  
  // Absences (pour les élèves)
  absences: [{
    date: {
      type: Date,
      required: true
    },
    justified: {
      type: Boolean,
      default: false
    },
    reason: {
      type: String,
      default: ''
    },
    declaredBy: {
      type: String,
      default: ''
    }
  }],
  
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// ==================== UNIQUE ENDROIT POUR LES INDEX ====================
// Tous les index sont définis ici pour éviter les doublons

// Index unique sur email
userSchema.index({ email: 1 }, { unique: true });

// Index uniques et sparce pour les codes
userSchema.index({ parentCode: 1 }, { unique: true, sparse: true });
userSchema.index({ childCode: 1 }, { unique: true, sparse: true });

// Index pour les recherches fréquentes
userSchema.index({ role: 1 });
userSchema.index({ className: 1 });
userSchema.index({ createdAt: -1 });

module.exports = mongoose.model('User', userSchema);