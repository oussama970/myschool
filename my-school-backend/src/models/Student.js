const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, lowercase: true },
  password: { type: String, required: true },
  isVerified: { type: Boolean, default: false },
  childCode: { type: String },
  parentCode: { type: String },
  className: { type: String, default: '' },
  linkedParents: [{ type: String, lowercase: true }],
  grades: [{
    subject: { type: String, required: true },
    grade: { type: Number, required: true, min: 0, max: 20 },
    appreciation: { type: String, default: '' },
    date: { type: Date, default: Date.now },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
    teacherName: { type: String, default: '' }
  }],
  absences: [{
    date: { type: Date, required: true },
    time: { type: String, default: '' },
    subject: { type: String, default: '' },
    justified: { type: Boolean, default: false },
    reason: { type: String, default: '' },
    declaredBy: { type: String, default: '' },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' }
  }],
  createdAt: { type: Date, default: Date.now }
});

// INDEX
studentSchema.index({ email: 1 }, { unique: true });
studentSchema.index({ parentCode: 1 }, { unique: true, sparse: true });
studentSchema.index({ childCode: 1 }, { unique: true, sparse: true });
studentSchema.index({ className: 1 });
studentSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Student', studentSchema);