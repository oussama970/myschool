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
    unique: true,
    lowercase: true,
    trim: true
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
    type: String,
    unique: true,
    sparse: true
  },
  parentCode: {
    type: String,
    unique: true,
    sparse: true
  },
  className: {
    type: String,
    default: ''
  },
  
  // Pour les parents
  linkedChild: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  linkedParents: [{
    type: String,
    lowercase: true
  }],
  children: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
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

// Index pour faciliter les recherches (uniquement ceux qui ne sont pas déjà dans unique: true)
// Les champs avec unique: true créent automatiquement un index
userSchema.index({ role: 1 });
userSchema.index({ className: 1 });
userSchema.index({ createdAt: -1 });

module.exports = mongoose.model('User', userSchema);