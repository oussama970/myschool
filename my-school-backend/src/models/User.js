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
    enum: ['student', 'parent'],
    required: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
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
  linkedChild: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  linkedParents: [{
    type: String,
    lowercase: true
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('User', userSchema);