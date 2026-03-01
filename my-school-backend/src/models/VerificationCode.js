const mongoose = require('mongoose');

const verificationCodeSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  code: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['email_verification', 'password_reset'],
    required: true
  },
  expiresAt: {
    type: Date,
    required: true,
    default: () => new Date(+new Date() + 15 * 60 * 1000)
  },
  used: {
    type: Boolean,
    default: false
  }
});

verificationCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('VerificationCode', verificationCodeSchema);