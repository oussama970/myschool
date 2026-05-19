const mongoose = require('mongoose');

const parentSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, lowercase: true },
  password: { type: String, required: true },
  isVerified: { type: Boolean, default: true },
  phoneNumber: { type: String, default: '' },
  linkedChildren: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
  createdAt: { type: Date, default: Date.now }
});

// INDEX UNIQUEMENT ICI
parentSchema.index({ email: 1 }, { unique: true });
parentSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Parent', parentSchema);