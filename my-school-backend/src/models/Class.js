const mongoose = require('mongoose');

const classSchema = new mongoose.Schema({
  name: { type: String, required: true },
  level: { type: String, required: true },
  group: { type: String, required: true },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  teacherName: { type: String, default: 'Non assigné' },
  capacity: { type: Number, default: 30 },
  room: { type: String, default: '' },
  studentCount: { type: Number, default: 0 },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
  createdAt: { type: Date, default: Date.now }
});

// INDEX UNIQUEMENT ICI
classSchema.index({ name: 1 }, { unique: true });
classSchema.index({ level: 1, group: 1 });
classSchema.index({ teacherId: 1 });

module.exports = mongoose.model('Class', classSchema);