const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, lowercase: true },
  password: { type: String, required: true },
  phoneNumber: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
  lastLogin: { type: Date }
});

// INDEX UNIQUEMENT ICI
adminSchema.index({ email: 1 }, { unique: true });
adminSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Admin', adminSchema);