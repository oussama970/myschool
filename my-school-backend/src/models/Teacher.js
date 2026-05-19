const mongoose = require('mongoose');

const teacherSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, lowercase: true },
  password: { type: String, required: true },
  isVerified: { type: Boolean, default: true },
  phoneNumber: { type: String, default: '' },
  subjects: [{ type: String }],
  assignedClasses: [{ type: String }],
  createdAt: { type: Date, default: Date.now }
});

// INDEX UNIQUEMENT ICI
teacherSchema.index({ email: 1 }, { unique: true });
teacherSchema.index({ assignedClasses: 1 });
teacherSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Teacher', teacherSchema);